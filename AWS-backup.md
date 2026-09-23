# AWS Backup aur Disaster Recovery (DR) – Simple Notes

## 1) AWS Backup kya hai?

AWS Backup ek centralized AWS service hai jo aapke multiple AWS resources ka backup, scheduling, retention, copy aur restore ko ek hi jagah se manage karta hai.

Simple language mein:

- Agar aapke paas EC2, EBS, RDS, EFS, DynamoDB, Aurora, FSx jaise resources hain
- To har resource ka backup alag-alag manage karne ke bajay
- AWS Backup se ek single backup policy banakar sab ko centrally protect kar sakte ho

### Example

Production application:

- EC2 = App server
- RDS = Database
- EFS = File storage

Agar aap backup plan bana rahe ho:

- Daily backup
- Retention = 30 days
- Copy to another region
- Restore karna possible when needed

Isse production resources corrupted ya deleted hone par recovery easy ho jata hai.

---

## 2) Disaster Recovery (DR) kya hota hai?

Disaster Recovery ka matlab hai:

> Disaster ya failure ke baad application, data aur infrastructure ko recover karke business ko dobara operational banana.

### Common disaster examples

- EC2 instance failure
- Database corruption
- Accidental deletion
- Region failure
- Ransomware attack
- Human mistake
- Application crash
- Infrastructure outage

### DR ke do important terms

#### RPO (Recovery Point Objective)

RPO ka matlab hai:

- Kitna purana data accept kiya ja sakta hai?

Example:

- RPO = 1 hour
- Matlab maximum 1 hour ka data loss acceptable hai

#### RTO (Recovery Time Objective)

RTO ka matlab hai:

- Application ko kitne time mein recover karna hai?

Example:

- RTO = 30 minutes
- Matlab disaster ke baad application 30 minutes ke andar available hona chahiye

---

## 3) AWS DR strategies (4 main types)

AWS disaster recovery strategies generally is order mein hote hain:

1. Backup & Restore
2. Pilot Light
3. Warm Standby
4. Multi-Site Active/Active

### Trend

- Left to right jaane par environment zyada ready hota hai
- Recovery faster hota hai
- Cost bhi zyada hoti hai

### Quick comparison

- Backup & Restore: simplest, cheapest, slowest recovery
- Pilot Light: core services running, rest created on demand
- Warm Standby: DR environment already running, quick recovery
- Multi-Site Active/Active: both sites active, fastest recovery, highest cost

---

## 4) Backup & Restore

Ye sabse simple DR strategy hai.

### Working model

Production environment -> Backup taken -> Disaster -> Restore -> Application online

### Example

- EC2, EBS, RDS daily backup liya
- Wednesday ko disaster hua
- Backup se EC2, EBS, RDS restore kiye
- App configure kiya
- Application online hua

### RPO/RTO

- RPO: usually hours
- RTO: usually hours

### Cost

- Low
- Kyunki DR environment continuously running nahi hota

### Suitable for

- Low-priority workloads
- Dev/test environment
- Applications where slow recovery is acceptable
- Cost-sensitive workloads

---

## 5) Pilot Light

Pilot Light ka matlab hai:

- Critical/core components already running hote hain
- Remaining services disaster ke time create/scale kiye jaate hain

### Example

Production database continuously replicated hoti hai, but full app stack running nahi hota.

During disaster:

- Core infrastructure already available
- Remaining resources scale/create hote hain
- App startup hota hai

### RPO/RTO

- RPO: usually tens of minutes
- RTO: usually tens of minutes

### Cost

- Backup & Restore se higher
- Lekin recovery faster

---

## 6) Warm Standby

Warm Standby mein DR environment already running hota hai, but smaller capacity mein.

### Example

Primary Region:

- EC2: 10 instances
- RDS: large

DR Region:

- EC2: 2 instances
- RDS: smaller

Disaster ke time:

- DR environment remains on
- Scale up hota hai
- Traffic redirect hota hai
- Application available hoti hai

### Benefit

- Recovery faster hota hai
- Infrastructure already ready hota hai

### RPO/RTO

- Generally minutes range

### Cost

- Higher than Pilot Light
- Kyunki DR environment always running hota hai

---

## 7) Multi-Site Active/Active

Ye most advanced architecture hai.

### Concept

- Dono regions simultaneously traffic serve karte hain
- Agar ek region down ho, second region traffic handle karta hai

### Example

- Region A active
- Region B active
- Users DNS/router ke through requests ko route karta hai
- Agar Region A fail ho, Region B continue serve karta hai

### RPO/RTO

- RPO: near real-time / very low
- RTO: very low

### Cost

- Highest
- Kyunki multiple production-capable environments chal rahi hoti hain

### Suitable for

- Mission-critical apps
- Financial systems
- Enterprise systems
- Workloads needing very low downtime

---

## 8) AWS Backup problem ko kaise solve karta hai?

Traditionally AWS services apne apne backup mechanism use karte hain, jaise:

- EC2 -> EBS / AMI
- RDS -> automated backup / snapshot
- EFS -> backup
- DynamoDB -> backup

Agar manual management hota hai:

- EC2 backup script
- RDS backup policy
- EFS backup policy
- DynamoDB backup policy
- Multiple scripts and policies
- Difficult to manage

AWS Backup centralized backup management provides karta hai.

### Simple architecture

AWS Backup

- Backup Plan
- Resource selection
- Backup Vault
- Recovery points

---

## 9) AWS Backup ke important components

AWS Backup ke main components:

- Backup Plan
- Backup Rule
- Backup Vault
- Recovery Point
- Backup Job
- Restore Job

### 1. Backup Plan

Backup Plan = backup policy

Isme define hota hai:

- Backup kab lena hai?
- Kitni frequency?
- Backup vault kaun sa hai?
- Backup kitne time retain karna hai?
- Cross-region copy chahiye?
- Lifecycle kya rahegi?

### Example

Backup Plan: Production-Backup

- Daily at 1 AM
- Retention: 30 days
- Weekly Sunday backup
- Retention: 90 days

### 2. Backup Rule

Backup Plan ke andar rules define hoti hain.

Example:

- Daily Rule: daily backup, retention 30 days
- Weekly Rule: weekly backup, retention 90 days
- Monthly Rule: monthly backup, retention 1 year

### 3. Backup Vault

Backup Vault backups ka logical storage location hota hai.

Example:

- EC2 recovery point
- RDS recovery point
- EBS recovery point
- EFS recovery point

Vault ke andar backup/recovery points store hote hain.

### 4. Recovery Point

Recovery Point ek specific snapshot/time hota hai jisse restore possible hota hai.

Example:

- 01 Sep 01:00 -> Recovery Point
- 02 Sep 01:00 -> Recovery Point
- 03 Sep 01:00 -> Recovery Point
- 04 Sep 01:00 -> Recovery Point

Agar database 4 Sep ko corrupt ho jaye to 3 Sep ka recovery point choose karke restore kiya ja sakta hai.

### 5. Backup Job

Backup Job wo actual processing task hoti hai jo backup create karti hai.

### 6. Restore Job

Restore Job backup recovery point ko original resource mein recover karne ke liye use hoti hai.

---

## 10) AWS Backup supported resources

AWS Backup multiple AWS services ko centrally protect kar sakta hai.

### Common examples

#### Compute & Storage

- EC2
- EBS
- EFS
- S3

#### Databases

- RDS
- Aurora
- DynamoDB
- Neptune

#### File systems

- Amazon FSx

#### Hybrid

- VMware environments

Note:

- Exact supported resources region aur service capability ke according vary karte hain

---

## 11) Tag-based backup

Ye feature production environments mein bahut useful hai.

### Example

Resources par tag set hai:

- Environment = Production

Backup plan rule:

- Tag: Environment = Production

Result:

- EC2-1 -> backup
- EC2-2 -> backup
- EC2-3 -> no backup

### Benefit

- Har resource manually select karne ki zarurat nahi hoti
- Automation easy hota hai

---

## 12) Policy-based backup

Manual approach:

- EC2 -> manual backup
- RDS -> manual backup
- EBS -> snapshot
- EFS -> manual backup

AWS Backup approach:

- Backup Plan
- Backup Rules
- Resource selection
- Automatic backup

This is called policy-based backup.

---

## 13) Cross-region backup

Aap backup ko ek region se doosre region mein copy kar sakte ho.

### Example

Production Region: us-east-1

Backup copied to: us-west-2

Flow:

Production Region -> Backup Vault -> Cross-region copy -> DR Region -> DR Backup Vault

### Why important?

- Agar primary region down ho jaye
- Backup ko alternate region se restore kiya ja sakta hai

---

## 14) Cross-account backup

Backup ko ek account se doosre account mein bhi copy kiya ja sakta hai.

### Example

- Account A = Production
- Account B = Backup/Security

### Benefit

- Agar production account compromise ho jaye
- Backup separate account mein safe reh sakta hai

---

## 15) Backup Vault Lock

Backup Vault Lock ek security feature hai jo backups ko immutable banane mein help karta hai.

### Concept

> Recovery points ko configured retention period ke liye change ya delete nahi kiya ja sakta.

### Why important?

- Attacker maliciously backup delete nahi kar paata
- Admin accidental deletion se protect hota hai

---

## 16) Ransomware scenario

Imagine attacker production environment compromise kar leta hai:

- EC2 delete
- Database damage
- Backup delete karne ki koshish

Agar secure backup design hai:

Production -> AWS Backup -> Locked Backup Vault -> Protected Recovery Points

Result:

- Production resources affected ho sakte hain
- Backup ko retention policy ke against easily delete/modify nahi kiya ja sakta

---

## 17) Vault Lock ke 2 modes

### Governance Mode

- Some authorized users override changes kar sakte hain
- More flexible

### Compliance Mode

- Lock stricter hota hai
- Retention protection ko bypass karna difficult hota hai

### Interview point

> Vault Lock helps enforce immutability and retention protection for backups.

---

## 18) Logically air-gapped vault

Ek logically air-gapped vault ka matlab hota hai:

- Backup vault normal production operations se logically isolated hota hai
- Backup data change/overwrite se protected rehta hai

### Purpose

- Ransomware protection
- Account compromise protection
- Disaster recovery
- Security isolation

---

## 19) AWS Backup malware protection

AWS Backup ecosystem me malware/ransomware-related protection capabilities available ho sakti hain, but important point ye hai:

> Backup alone malware ko prevent nahi karta.

Backup ka purpose mainly hota hai:

- Data protection
- Recovery

Additional security controls include:

- IAM
- MFA
- CloudTrail
- GuardDuty
- Security Hub
- SCP
- KMS
- Vault Lock
- Cross-account backup

---

## 20) Backup lifecycle

Backup ko permanently store karna expensive ho sakta hai. Isliye lifecycle policy use hoti hai.

### Example lifecycle

- Day 0: backup created
- Warm storage
- After 30 days: move to cold storage / long-term retention
- Expire after policy period

### Example policy

- Daily backup
- Retention: 30 days
- Then expire

Or

- Daily backup -> 30 days
- Weekly backup -> 90 days
- Monthly backup -> 1 year

---

## 21) AWS Backup Console se backup plan banana

### Console path

AWS Console -> AWS Backup -> Backup plans -> Create backup plan

### 3 common ways

#### Option 1: Start with a template

- AWS predefined template use karna
- Example: Daily-35day-Retention
- Or Daily-Weekly-Monthly-5yr-Retention

#### Option 2: Build a new plan

You manually configure:

- Backup plan name
- Backup rule
- Schedule
- Vault
- Retention
- Copy actions

#### Option 3: Define using JSON

- JSON format mein backup plan define kar sakte ho
- Good for automation and IaC workflows

---

## 22) Backup frequency

AWS Backup supports many frequencies, like:

- Hourly
- Every 12 hours
- Daily
- Weekly
- Monthly
- Custom cron expression

### Example

- Daily backup at 1 AM

Custom cron se specific time schedule define kar sakte ho.

---

## 23) Backup window

Backup job ke liye ek time window define ki ja sakti hai.

### Example

- Backup start: 1:00 AM
- Completion window: 8 hours

Isse backup operations ko business hours ke according schedule kiya ja sakta hai.

---

## 24) Backup vault selection

Backup rule mein aap vault select karte ho.

### Example options

- Default vault
- Production Backup Vault
- Development Backup Vault
- Compliance Backup Vault

Production environment me logically separated vault useful hote hain.

---

## 25) Resource assignment

Backup plan create karne ke baad resources assign karte hain.

### Common approaches

- Resource ID
- Specific resource select
- Tag-based selection

### Example

- EC2 instance
- RDS database
- EFS file system

---

## 26) Quick summary

AWS Backup ka main idea ye hai:

- Centralized backup management
- Policy-based automation
- Retention and lifecycle handling
- Cross-region / cross-account copy
- Security and immutability with vault lock
- Recovery during disaster or ransomware attack

### In one line

AWS Backup ek standardized, secure aur centralized way hai AWS resources ko backup karne aur recover karne ke liye.

---

## 27) Interview-friendly explanation

If interview mein pucha jaye:

> AWS Backup kya hai?

Answer:

AWS Backup ek centralized service hai jo AWS resources ko scheduled, policy-based aur secure way mein backup karne aur recover karne mein help karta hai. Isme backup plan, backup vault, retention rules aur recovery points use hote hain.

> RPO aur RTO kya hota hai?

- RPO: data loss ka maximum acceptable threshold
- RTO: recovery ke liye maximum acceptable time

> Vault Lock kya hai?

Vault Lock backups ko retention period ke liye immutable banane mein help karta hai, jisse accidental ya malicious deletion ka risk kam hota hai.

> Why AWS Backup is important?

Because it centralizes backup management, helps in DR, reduces operational complexity, and supports security needs like cross-region recovery and immutable backups.

---

## 28) Final takeaway

AWS Backup sirf backup service nahi hai.

Ye ek disaster recovery aur resilience strategy ka important part hai.

Agar aapko resilient, secure aur manageable recovery setup banana hai, to AWS Backup ek strong foundation hai.
