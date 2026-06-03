# HMI Stars - Roadmap & Prochaines Étapes

Voici les 15 points stratégiques pour finaliser et faire évoluer la solution HMI Stars.

## 🟢 Priorité Haute (Immédiat)


## 🟡 Priorité Moyenne (Amélioration UX)

## 🔵 Priorité Basse (Fonctionnalités Avancées)
9.  **AI Warning Generator** : Un assistant IA qui suggère automatiquement le type d'avertissement basé sur le comportement du salarié.


### 🚀 High-Impact Core Features

4.  **Advanced PDF & CSV Export Suite**  
    *   *Detail*: On the Web Platform, add a "Generate Report" button that creates a monthly PDF of employee attendance and a CSV export for payroll systems.

---

### 💻 Web Platform Fine-Grained Details
---

### 📱 Mobile App Optimization
10. **Smart Stream Reconnection (Heartbeat)**  
    *   *Detail*: Implement a listener that detects "Connectivity Changes". If the connection is lost, show a subtle "Reconnecting..." bar at the top and auto-refresh the stream when back online.
---

### 🛠️ Maintenance & Scalability
13. **Pagination & Lazy Loading (Infinite Scroll)**  
    *   *Detail*: Currently, we load hundreds of messages/employees at once. Implement `ScrollController` listeners to load data in chunks of 20 to prevent memory lag as the DB grows.
14. **Profile Media Refinement**  
    *   *Detail*: Finalize the Supabase Storage logic to allow real-time cropping and uploading of profile pictures for both Enterprises and Employees.
