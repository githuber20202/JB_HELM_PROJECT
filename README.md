# 📦 Helm + Kubernetes לאפליקציית Flask (ויזואלי)

למטה תמצאו ייצוגים ויזואליים מלאים: ארכיטקטורה, מבנה הצ׳ארט, זרימות התקנה/שדרוג/רולבק, מיפוי values לתבניות, ולוגיקה של Service לפי ingress.

## 🏗️ ארכיטקטורה (Flow)
```mermaid
flowchart TD
  U[משתמש/דפדפן] -->|HTTP/HTTPS| Q{ingress.enabled?}
  Q -- כן --> IG[Ingress]
  Q -- לא --> SvcL[Service: LoadBalancer]
  IG --> SvcC[Service: ClusterIP]
  SvcC --> D[Deployment]
  SvcL --> D
  D --> RS[ReplicaSet]
  RS --> P1[(Pod Flask)]
  RS --> P2[(Pod Flask)]
  P1 -->|AWS SDK| AWS[(AWS APIs)]
  P2 -->|AWS SDK| AWS
```

## 🧱 אובייקטים ב‑Kubernetes
```mermaid
flowchart LR
  Ingress --> Service
  Service -->|selector| P1(Pod) & P2(Pod)
  Deployment --> RS(ReplicaSet)
  RS --> P1
  RS --> P2
```

## 🧩 מבנה הצ׳ארט (Helm Chart Structure)
```mermaid
flowchart LR
  A[flask-aws-monitor] --> B[Chart.yaml]
  A --> C[values.yaml]
  A --> D[templates/]
  D --> D1[_helpers.tpl]
  D --> D2[deployment.yaml]
  D --> D3[service.yaml]
  D --> D4[ingress.yaml]
  D --> D5[NOTES.txt]
```

או כעץ קבצים:
```
flask-aws-monitor/
├─ Chart.yaml
├─ values.yaml
└─ templates/
   ├─ _helpers.tpl
   ├─ deployment.yaml
   ├─ service.yaml
   ├─ ingress.yaml
   └─ NOTES.txt
```

## ⚙️ values.yaml → איפה זה משפיע?
```mermaid
classDiagram
  class Values{
    image.repository
    image.tag
    image.pullPolicy
    replicaCount
    containerPort
    aws.useExistingSecret
    aws.existingSecretName
    aws.env.*
    service.port
    service.targetPort
    ingress.enabled
    ingress.className
    ingress.hosts
    ingress.tls
    resources.requests/limits
    imagePullSecrets[]
  }
  class Deployment
  class Service
  class Ingress
  Values --> Deployment : env, image, replicas, port, resources
  Values --> Service : ports, selector
  Values --> Ingress : hosts, className, tls
```

## 🔀 לוגיקת בחירת Service לפי ingress (בונוס)
```mermaid
flowchart LR
  E[ingress.enabled] -->|true| C[ClusterIP]
  E -->|false| L[LoadBalancer]
```

ממומש ב‑`templates/service.yaml` עם `ternary` על `.Values.ingress.enabled`.

## 🚀 תהליך התקנה/בדיקה/גישה
```mermaid
flowchart TD
  A[בדיקת קלאסטר] --> B[helm lint]
  B --> C[helm template (אופציונלי)]
  C --> D[helm install flask-monitor ./flask-aws-monitor]
  D --> E[kubectl get deploy,po,svc -l app.kubernetes.io/instance=flask-monitor]
  E --> F{ingress.enabled?}
  F -- כן --> G[גלישה ל‑host מה‑values]
  F -- לא --> H[קבלת External IP מה‑Service]
```

פקודות לדוגמה:
```
kubectl get nodes
helm lint ./flask-aws-monitor
helm template flask-monitor ./flask-aws-monitor | kubectl apply --dry-run=client -f -
helm install flask-monitor ./flask-aws-monitor
kubectl get deploy,po,svc -l app.kubernetes.io/instance=flask-monitor
```

גישה ללא Ingress:
```
kubectl get svc flask-monitor-flask-aws-monitor \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# ואז: http://<EXTERNAL_IP>:5001/
```

## 🔁 שדרוגים ורולבק
```mermaid
flowchart TD
  U1[עריכת values.yaml] --> U2[helm upgrade flask-monitor ./flask-aws-monitor]
  U2 --> U3[בדיקת משאבים/לוגים]
  U3 -->|בעיה| U4[helm rollback flask-monitor <revision>]
```

## 🔐 AWS Secrets (ויזואלי)
```mermaid
flowchart LR
  subgraph Cluster
    D[(Deployment)] -->|valueFrom: secretKeyRef| P[(Pod Env)]
    S[(Secret: aws-credentials)] --> P
  end
```

יצירת Secret לדוגמה:
```
kubectl create secret generic aws-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=XXX \
  --from-literal=AWS_SECRET_ACCESS_KEY=YYY \
  --from-literal=AWS_DEFAULT_REGION=us-east-1
```
הגדרות ב‑values:
```
aws:
  useExistingSecret: true
  existingSecretName: aws-credentials
```

## 🧪 בריאות האפליקציה
```mermaid
sequenceDiagram
  participant K as Kubelet
  participant P as Pod (Flask)
  K->>P: readinessProbe GET /
  P-->>K: 200 OK (Ready)
  K->>P: livenessProbe GET /
  P-->>K: 200 OK (Alive)
```

## 🛠️ טכנולוגיות
- Kubernetes, Helm (application chart)
- Docker Image: `formy5000/resources_viewer:latest` (ניתן להחלפה)
- Flask (פורט 5001)

## 👀 תצוגה מקדימה (VS Code Preview)
- דרישות: VS Code 1.67+ (כולל Mermaid מובנה) או התקנת התוסף `bierner.markdown-mermaid`.
- פתיחה: `Ctrl+Shift+V` או פקודת Command Palette: `Markdown: Open Preview to the Side`.
- אם התרשימים לא מוצגים:
  - אשרו Trust לחלון העבודה (Workspace Trust).
  - ודאו שהתוסף `Markdown Mermaid` פעיל (Extensions → חיפוש mermaid).
  - לחלופין התקינו `Markdown Preview Mermaid Support`.

## ✅ מה מכוסה לפי ההוראות
- Deployment: תדמית מה‑Docker Hub, משיכת latest, env ל‑AWS, פורט 5001, probes, resources.
- Service: פורט 5001, סוג נקבע אוטומטית לפי `ingress.enabled` (בונוס).
- Ingress: נוצר רק כאשר `ingress.enabled=true` ומנתב לפי hosts/paths.
- values.yaml: תדמית/תג, משתני AWS, replicaCount, משאבים, ingress.
- labels אחידים דרך `_helpers.tpl`.

---
קובץ זה ממוקד בויזואליזציות כדי לאפשר קליטה מהירה של הארכיטקטורה וה‑flow. לקבלת פירוט טכני נוסיף/נעדכן לפי צורך.
