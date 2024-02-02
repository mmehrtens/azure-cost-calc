
### Example 1

$\psi_{stacc} = 3200\; \textrm{MB/s}\;,\quad \psi_{worker} = 125\; \textrm{MB/s}$

$N_{vm} = 1000$

$V_{incr} = N_{vm} \cdot 50\;\textrm{GB} \approx 50\;\textrm{TB}$

$T_{backup} = 8\;\textrm{hours}$

Calculating the number of worker instances using (6):
$$W_{veeam} = \frac{1024}{60} \cdot \sqrt{\frac{50\cdot 1000}{8 \cdot 125}}$$
$$\approx 120.68\quad \mathbf{= 121}\; \textbf{worker instances}\quad \textrm{(rounded to full integer)}$$

Calculating the number of storage accounts using (8):
$$N_{stacc}= \frac{1024}{60\cdot 3200} \cdot \sqrt{\frac{50\cdot 1000 \cdot 125}{8}}$$
$$ \approx 4.714\quad \mathbf{= 5}\; \textbf{storage accounts}\quad \textrm{(rounded to full integer)}$$

### Example 2 (sanity check using only a few very small workloads)

$\psi_{stacc} = 3200\; \textrm{MB/s}\;,\quad \psi_{worker} = 125\; \textrm{MB/s}$

$N_{vm} = 50$

$V_{incr} = N_{vm} \cdot 5\;\textrm{GB} = 250\;\textrm{GB}\approx 0.25\;\textrm{TB}$

$T_{backup} = 8\;\textrm{hours}$

Calculating the number of worker instances using (6):
$$W_{veeam} = \frac{1024}{60} \cdot \sqrt{\frac{0.25\cdot 50}{8 \cdot 125}}$$
$$\approx 1.908\quad \mathbf{= 2}\; \textbf{worker instances}\quad \textrm{(rounded to full integer)}$$

Calculating the number of storage accounts using (8):
$$N_{stacc}= \frac{1024}{60\cdot 3200} \cdot \sqrt{\frac{0.25\cdot 50 \cdot 125}{8}}$$
$$ \approx 0.075\quad \mathbf{= 1}\; \textbf{storage account}\quad \textrm{(rounded to full integer)}$$

## Appliance Requirements

A single storage account has a maximum ingest limit of $\psi_{stacc}$ (in MB/s). In the larger Azure regions, it is usually given as

$$\psi_{stacc} = 60\; \textrm{Gb/s} = 7.5\;\textrm{GB/s} = 7680\; \textrm{MB/s}\;$$ (1)

<!---
If we leverage a number of $N_{stacc}$ storage accounts as targets used in parallel, the total available ingress is defined as

$$\Psi_{storage} = N_{stacc} \cdot \psi_{stacc}$$
--->

As a single policy within Veeam Backup for Azure is targeting a single storage account to create primary backups, we have to make sure that the backup traffic created by a single policy does not exceed this limit to achieve optimal performance. The backup traffic generated by a single policy is defined by the number $W_{policy}$ of worker instances running in parallel to process the number $ N_{vm}^{policy}$ of VMs in the policy. Each worker has a processing throughput given as $\psi_{worker}$ (in MB/s). So, the total backup load created by a single policy is defined as

$$\psi_{policy} = W_{policy} \cdot \psi_{worker}$$ (2)

The maximum of $\psi_{policy}$ is defined by the storage account ingress limit, i.e. for a maxed out policy in terms of throughput we can assume

$$\psi_{policy} = \psi_{stacc}$$ (3)

Combining (2) and (3) gives us the maximum number $W_{max/policy}$ of workers a single policy can use

$$ W_{max/policy} = \frac{\psi_{policy}}{\psi_{worker}} = \frac{\psi_{stacc}}{\psi_{worker}} $$ (4)

By default, Veeam Backup for Azure will create a worker instance for each VM in the running policy, i.e. $W_{policy} = N_{vms/policy}$. The workers have to run multiple times if we limit the number of worker instances to be $\leq N_{vms/policy}\;$. The amount of required runs can be calculated as 

$$
\rho_{workers} = 
  \begin{cases}
    \quad \displaystyle\frac {N_{vms/policy}}{W_{worker}} & \quad\quad \textrm{if}\quad {W_{worker}} \leq N_{vms/policy} \\
    \\
    \quad 1 & \quad\quad \textrm{if}\quad {W_{worker}} > N_{vms/policy}
  \end{cases}
$$ (5)