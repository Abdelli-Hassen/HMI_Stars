# 📝 Task Checklist (TODO) - HMI Stars PFE Report

All automated tasks to structure, write, and render your graduation project (PFE) report have been completed!

---

## 1. Personalize Information in `main.tex` [COMPLETED]
*   **Students**: Added Hassen ABDELLI and Yassine HADJ as co-authors on the French cover page.
*   **Academic Supervisor**: Set to `M. Aymen CHAABOUNI` (Encadrant Académique).
*   **Company Supervisor**: Set to `M. Salem AKLI` (Encadrant en Entreprise).
*   **University Logo**: Configured to display `fstsbz_logo.jpg` directly on the cover page.
*   **Academic Year**: Configured to `A.U. : 2025/2026`.
*   **Jury**: Formatted the jury table with placeholders for President and Rapporteur.

---

## 2. Generate UML and Architecture Diagrams [COMPLETED]
*   **UML Source Files**: Created inside the `Rapport/diagrams/` folder.
*   **Rendered Diagrams**: Generated and saved as `use_case_diagram.png`, `sequence_diagram_auth.png`, `class_diagram.png`, and `architecture_diagram.png` in the `Rapport/diagrams/` directory. They are fully referenced and visible in `main.tex`.

---

## 3. Handle Spaces in Screenshot Names [COMPLETED]
*   We loaded the `grffile` package in the LaTeX preamble to natively support space-separated screenshot paths (e.g. `"capture de lapplication/1 welcome screen".jpeg`).
*   Placed all screens under Chapter 3 using high-fidelity subfigures, captions, and proper references.

---

## 4. Compile the Report
To compile the final PDF:
*   **Recommended**: Upload the `Rapport/` folder to **Overleaf** (https://www.overleaf.com/).
*   **Compiler Engine**: Switch the Overleaf compiler to **XeLaTeX** or **LuaLaTeX** (Menu -> Compiler -> XeLaTeX) so that it compiles the Arabic text on the back cover without any font issues.
*   **Local compilation**: You can also use local tools like VS Code with *LaTeX Workshop* or TeXworks, selecting XeLaTeX as the build tool.

