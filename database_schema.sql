-- ==========================================
-- HMI Stars - Complete Database Schema
-- Exported from Live Supabase instance
-- Date: 2026-05-22
-- ==========================================

-- ------------------------------------------
-- Custom Types (Enums)
-- ------------------------------------------

CREATE TYPE public.role_utilisateur AS ENUM ('admin', 'moderateur', 'secretaire');
CREATE TYPE public.type_contrat AS ENUM ('CDI', 'CDD', 'Apprentissage', 'Stage');
CREATE TYPE public.type_document AS ENUM ('fournisseur', 'releve_bancaire', 'chiffre_affaires', 'autre', 'kbis', 'tva', 'siret', 'rib', 'statuts', 'media');
CREATE TYPE public.type_avertissement AS ENUM ('ficheAvertissement', 'convocation', 'information');

-- ------------------------------------------
-- Tables
-- ------------------------------------------

-- Table: entreprises
CREATE TABLE public.entreprises (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    raison_sociale text NOT NULL,
    nom_gerant text NOT NULL DEFAULT ''::text,
    description text DEFAULT ''::text,
    email text NOT NULL,
    statut text NOT NULL DEFAULT 'EN COURS'::text,
    adresse text DEFAULT ''::text,
    telephone text DEFAULT ''::text,
    logo_url text,
    effectif integer DEFAULT 0,
    n_siren text DEFAULT ''::text,
    siret text DEFAULT ''::text,
    forme_juridique text DEFAULT ''::text,
    tva_intracommunautaire text DEFAULT ''::text,
    n_rcs text DEFAULT ''::text,
    capital_social text DEFAULT ''::text,
    code_ape text DEFAULT ''::text,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    mis_a_jour_le timestamp with time zone NOT NULL DEFAULT now(),
    jeton_notification text,
    CONSTRAINT entreprises_pkey PRIMARY KEY (id),
    CONSTRAINT entreprises_email_key UNIQUE (email)
);

-- Table: salaries
CREATE TABLE public.salaries (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    entreprise_id uuid NOT NULL,
    genre text DEFAULT ''::text,
    nom text NOT NULL,
    prenom text NOT NULL,
    nom_de_naissance text DEFAULT ''::text,
    numero_securite_sociale text DEFAULT ''::text,
    date_naissance date,
    lieu_naissance text DEFAULT ''::text,
    nationalite text DEFAULT ''::text,
    adresse_postale text DEFAULT ''::text,
    telephone text DEFAULT ''::text,
    email text DEFAULT ''::text,
    date_embauche date,
    type_contrat public.type_contrat NOT NULL DEFAULT 'CDI'::public.type_contrat,
    date_fin_contrat date,
    emploi_poste text DEFAULT ''::text,
    est_archive boolean NOT NULL DEFAULT false,
    avatar_url text,
    a_piece_identite boolean NOT NULL DEFAULT false,
    a_carte_vitale boolean NOT NULL DEFAULT false,
    a_justificatif_domicile boolean NOT NULL DEFAULT false,
    a_contrat_signe boolean NOT NULL DEFAULT false,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    cin text DEFAULT ''::text,
    description text DEFAULT ''::text,
    CONSTRAINT salaries_pkey PRIMARY KEY (id),
    CONSTRAINT salaries_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE
);

-- Table: utilisateurs_plateforme
CREATE TABLE public.utilisateurs_plateforme (
    id uuid NOT NULL,
    nom text NOT NULL DEFAULT ''::text,
    email text NOT NULL DEFAULT ''::text,
    role public.role_utilisateur NOT NULL DEFAULT 'secretaire'::public.role_utilisateur,
    telephone text DEFAULT ''::text,
    avatar_url text,
    organisation text NOT NULL DEFAULT 'HMI Stars Consulting'::text,
    preferences jsonb DEFAULT '{}'::jsonb,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    mis_a_jour_le timestamp with time zone NOT NULL DEFAULT now(),
    cin text DEFAULT ''::text,
    est_approuve boolean NOT NULL DEFAULT false,
    CONSTRAINT utilisateurs_plateforme_pkey PRIMARY KEY (id),
    CONSTRAINT utilisateurs_plateforme_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Table: notes_entreprises
CREATE TABLE public.notes_entreprises (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    entreprise_id uuid NOT NULL,
    titre text NOT NULL DEFAULT ''::text,
    contenu text DEFAULT ''::text,
    est_rappel boolean NOT NULL DEFAULT false,
    date_rappel timestamp with time zone,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    tag text DEFAULT 'Note'::text,
    is_pinned boolean DEFAULT false,
    CONSTRAINT notes_entreprises_pkey PRIMARY KEY (id),
    CONSTRAINT notes_entreprises_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE
);

-- Table: messages
CREATE TABLE public.messages (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    entreprise_id uuid NOT NULL,
    contenu text NOT NULL DEFAULT ''::text,
    est_envoye_par_user boolean NOT NULL DEFAULT true,
    est_fichier boolean NOT NULL DEFAULT false,
    fichier_url text,
    fichier_nom text,
    type_document public.type_document,
    date_envoi timestamp with time zone NOT NULL DEFAULT now(),
    est_lu boolean DEFAULT false,
    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE
);

-- Table: pointages
CREATE TABLE public.pointages (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    salarie_id uuid NOT NULL,
    entreprise_id uuid NOT NULL,
    date date NOT NULL,
    est_pointe boolean NOT NULL DEFAULT false,
    note text,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT pointages_pkey PRIMARY KEY (id),
    CONSTRAINT pointages_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE,
    CONSTRAINT pointages_salarie_id_fkey FOREIGN KEY (salarie_id) REFERENCES public.salaries(id) ON DELETE CASCADE
);

-- Table: modeles_avertissements
CREATE TABLE public.modeles_avertissements (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    entreprise_id uuid,
    titre text NOT NULL,
    contenu text NOT NULL DEFAULT ''::text,
    type public.type_avertissement NOT NULL DEFAULT 'information'::public.type_avertissement,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT modeles_avertissements_pkey PRIMARY KEY (id),
    CONSTRAINT modeles_avertissements_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE SET NULL
);

-- Table: taches_urgentes
CREATE TABLE public.taches_urgentes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    entreprise_id uuid NOT NULL,
    titre text NOT NULL,
    description text DEFAULT ''::text,
    date_echeance timestamp with time zone NOT NULL,
    accomplie boolean NOT NULL DEFAULT false,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT taches_urgentes_pkey PRIMARY KEY (id),
    CONSTRAINT taches_urgentes_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE
);

-- Table: preferences
CREATE TABLE public.preferences (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    entreprise uuid UNIQUE NOT NULL,
    favori boolean DEFAULT false,
    muet boolean DEFAULT false,
    cree_le timestamp with time zone DEFAULT now(),
    CONSTRAINT preferences_pkey PRIMARY KEY (id),
    CONSTRAINT preferences_entreprise_fkey FOREIGN KEY (entreprise) REFERENCES public.entreprises(id) ON DELETE CASCADE
);

-- Table: fichiers
CREATE TABLE public.fichiers (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    entreprise_id uuid NOT NULL,
    nom text NOT NULL,
    url text NOT NULL,
    est_envoye_par_user boolean NOT NULL DEFAULT false,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    type_document public.type_document,
    CONSTRAINT fichiers_pkey PRIMARY KEY (id),
    CONSTRAINT fichiers_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE
);

-- Table: conges
CREATE TABLE public.conges (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    salarie_id uuid NOT NULL,
    entreprise_id uuid NOT NULL,
    type_conge text NOT NULL, -- e.g., 'conge_paye', 'maladie', 'rtt', 'exceptionnel', 'autre'
    date_debut date NOT NULL,
    date_fin date NOT NULL,
    est_demi_journee boolean NOT NULL DEFAULT false,
    statut text NOT NULL DEFAULT 'en_attente', -- 'en_attente', 'approuve', 'refuse'
    commentaire text DEFAULT ''::text,
    cree_le timestamp with time zone NOT NULL DEFAULT now(),
    mis_a_jour_le timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT conges_pkey PRIMARY KEY (id),
    CONSTRAINT conges_entreprise_id_fkey FOREIGN KEY (entreprise_id) REFERENCES public.entreprises(id) ON DELETE CASCADE,
    CONSTRAINT conges_salarie_id_fkey FOREIGN KEY (salarie_id) REFERENCES public.salaries(id) ON DELETE CASCADE
);

-- ------------------------------------------
-- Row Level Security (RLS)
-- ------------------------------------------

ALTER TABLE public.entreprises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.utilisateurs_plateforme ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes_entreprises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pointages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modeles_avertissements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taches_urgentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fichiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conges ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------
-- Functions
-- ------------------------------------------

CREATE OR REPLACE FUNCTION public.maj_mis_a_jour_le()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.mis_a_jour_le = now();
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.creer_profil_plateforme()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF COALESCE(NEW.raw_user_meta_data->>'user_type', '') = 'client' THEN
        RETURN NEW;
    END IF;

    -- Insert or update the public profile immediately
    INSERT INTO public.utilisateurs_plateforme (id, nom, email, role, telephone, cin, organisation, email_confirme)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nom', split_part(NEW.email, '@', 1), 'Utilisateur'),
        COALESCE(NEW.email, ''),
        'secretaire'::role_utilisateur,
        COALESCE(NEW.raw_user_meta_data->>'telephone', ''),
        COALESCE(NEW.raw_user_meta_data->>'cin', ''),
        COALESCE(NEW.raw_user_meta_data->>'organisation', 'HMI Stars Consulting'),
        (NEW.email_confirmed_at IS NOT NULL)
    )
    ON CONFLICT (id) DO UPDATE SET
        nom = EXCLUDED.nom,
        email = EXCLUDED.email,
        telephone = EXCLUDED.telephone,
        cin = EXCLUDED.cin,
        organisation = EXCLUDED.organisation,
        email_confirme = EXCLUDED.email_confirme;

    RETURN NEW;
END;
$function$;

-- ------------------------------------------
-- Triggers
-- ------------------------------------------

DROP TRIGGER IF EXISTS declencheur_maj_entreprises ON public.entreprises;
CREATE TRIGGER declencheur_maj_entreprises
    BEFORE UPDATE ON public.entreprises
    FOR EACH ROW
    EXECUTE FUNCTION public.maj_mis_a_jour_le();

DROP TRIGGER IF EXISTS declencheur_maj_utilisateurs ON public.utilisateurs_plateforme;
CREATE TRIGGER declencheur_maj_utilisateurs
    BEFORE UPDATE ON public.utilisateurs_plateforme
    FOR EACH ROW
    EXECUTE FUNCTION public.maj_mis_a_jour_le();

DROP TRIGGER IF EXISTS creation_utilisateur_auth ON auth.users;
CREATE TRIGGER creation_utilisateur_auth
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.creer_profil_plateforme();

DROP TRIGGER IF EXISTS declencheur_maj_conges ON public.conges;
CREATE TRIGGER declencheur_maj_conges
    BEFORE UPDATE ON public.conges
    FOR EACH ROW
    EXECUTE FUNCTION public.maj_mis_a_jour_le();

-- ------------------------------------------
-- RLS Policies
-- ------------------------------------------

-- utilisateurs_plateforme
CREATE POLICY "acces_complet_service" ON public.utilisateurs_plateforme FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "lecture_propre_profil" ON public.utilisateurs_plateforme FOR SELECT USING (auth.uid() = id);

-- entreprises
CREATE POLICY "acces_complet_entreprises" ON public.entreprises FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "client_lecture_propre_entreprise" ON public.entreprises FOR SELECT USING (email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text);
CREATE POLICY "client_update_propre_entreprise" ON public.entreprises FOR UPDATE USING (email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text) WITH CHECK (email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text);

-- salaries
CREATE POLICY "acces_complet_salaries" ON public.salaries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "client_lecture_propres_salaries" ON public.salaries FOR SELECT USING (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text)));

-- messages
CREATE POLICY "acces_complet_messages" ON public.messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "client_envoi_propres_messages" ON public.messages FOR INSERT WITH CHECK (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text)));
CREATE POLICY "client_lecture_propres_messages" ON public.messages FOR SELECT USING (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text)));

-- notes_entreprises
CREATE POLICY "acces_complet_notes" ON public.notes_entreprises FOR ALL USING (true) WITH CHECK (true);

-- pointages
CREATE POLICY "acces_complet_pointages" ON public.pointages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "client_gestion_propres_pointages" ON public.pointages FOR ALL USING (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text))) WITH CHECK (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text)));

-- modeles_avertissements
CREATE POLICY "acces_complet_avertissements" ON public.modeles_avertissements FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "client_lecture_modeles" ON public.modeles_avertissements FOR SELECT USING (((entreprise_id IS NULL) OR (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text)))));

-- taches_urgentes
CREATE POLICY "acces_complet_taches" ON public.taches_urgentes FOR ALL USING (true) WITH CHECK (true);

-- preferences
CREATE POLICY "Autoriser toutes operations sur preferences" ON public.preferences FOR ALL USING (true) WITH CHECK (true);

-- fichiers
CREATE POLICY "acces_complet_fichiers" ON public.fichiers FOR ALL USING (true) WITH CHECK (true);

-- conges
CREATE POLICY "acces_complet_conges" ON public.conges FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "client_gestion_propres_conges" ON public.conges FOR ALL USING (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text))) WITH CHECK (entreprise_id IN ( SELECT entreprises.id FROM entreprises WHERE (entreprises.email = (( SELECT users.email FROM auth.users WHERE (users.id = auth.uid())))::text)));
