## Veeam Worker Instances

Calculating the required number of worker instances $W_{veeam}$ as a function of the backup window $T_{incr} \;$:

Let's assume we're running a number of $W_{veeam}$ worker instances, each providing a maximum throughput of $\psi_{worker}$ MB/s, so the total throughput $\Psi_{total}$ can theoretically be calculated as

$$\Psi_{total} = W_{veeam} \cdot  \psi_{worker}$$ (1)

To backup a given volume $V$ of data (in TB), these workers would require a time of

$$ T = \frac{V \cdot 1024^2}{\Psi_{total}}
= \frac{V\cdot 1024^2}{W_{veeam}\cdot\psi_{worker}}\quad\textrm{seconds, or}$$

$$ T = \frac{V\cdot 1024^2}{W_{veeam}\cdot\psi_{worker}\cdot 3600}\quad\textrm{hours.}$$ (2)

Per default, Veeam Backup for Azure would start a dedicated worker instance for each VM to be backed up, i.e $W_{veeam}$ would be equal to $N_{vm}$. But as we are limiting the number of worker instances to a value less than the number of protected VMs, we have to consider running the chosen amount of workers multiple times in sequence, as each worker would still only process a single workload. The required number of these "worker runs" is determined by

$$\rho_{workers} =  \frac{N_{vm}}{W_{veeam}}$$ (3)

Hence, we need to multiply the time $T$ with this factor to obtain the time required (in hours) to create an incremental backup of a number of $N_{vm}$ VMs (with $N_{vm}\geq W_{veeam}$):

$$T_{incr} = T \cdot \rho_{workers} $$ (4)

By substituting $T$ with (2) and $\rho_{workers}$ with (3), we get

$$T_{incr} = \frac{V_{veeam}^{incr}\cdot 1024^2}{W_{veeam}\cdot\psi_{worker}\cdot 3600} \cdot \frac{N_{vm}}{W_{veeam}}$$

Simplified

$$T_{incr} = \frac{1024^2}{3600} \cdot \frac{V_{veeam}^{incr}\cdot N_{vm}}{\big(W_{veeam}\big)^2 \cdot \psi_{worker}}$$ (5)

By solving this equation for $W_{veeam}\;$, we are now able to calculate the required number of workers as a function of their throughput, the number and (incremental) backup volume of protected VMs as well as the limiting backup window $T_{incr}$ (in hours):

$$W_{veeam} = \sqrt{\frac{1024^2}{3600}\cdot \frac{V_{veeam}^{incr}\cdot N_{vm}}{T_{incr} \cdot \psi_{worker}}}$$

Simplified

$$W_{veeam} = \frac{1024}{60} \cdot \sqrt{\frac{V_{veeam}^{incr}\cdot N_{vm}}{T_{incr} \cdot \psi_{worker}}}$$ (6)

We must not forget that our target storage accounts also have a throughput limit $\psi_{stacc}\;$. So we have to calculate the maximum throughput required during our "worker runs" to determine the required number of traget storage accounts capable of ingesting the data:

$$N_{stacc} = \frac{\Psi_{total}}{\Psi_{stacc}}$$

Substituting $\Psi_{total}$ with (1) results in 

$$N_{stacc} = \frac{W_{veeam} \cdot \psi_{worker}}{\Psi_{stacc}}$$ (7)

By using (6) to substitute $W_{veeam}$ in (7), the number of required storage accounts can be calculated as a function of well known input parameters $\;N_{vm}\;,V_{veeam}^{incr}\;,\psi_{worker}\;,\Psi_{stacc}\;,\textrm{and}\; T_{incr}\;.$

$$N_{stacc} = \frac{1024}{60}\cdot \frac{\psi_{worker}}{\Psi_{stacc}} \cdot \sqrt{\frac{V_{veeam}^{incr}\cdot N_{vm}}{T_{incr} \cdot \psi_{worker}}}$$

$$= \frac{1024}{60\cdot \Psi_{stacc}} \cdot \sqrt{\frac{V_{veeam}^{incr}\cdot N_{vm} \cdot \psi_{worker}}{T_{incr}}}$$

### Example

$$\Psi_{stacc} = 3200\; \textrm{MB/s}$$
$$\psi_{worker} = 125\; \textrm{MB/s}$$
$$N_{vm} = 1000$$
$$V_{veeam}^{incr} = N_{vm} \cdot 50\;\textrm{GB} \approx 50\;\textrm{TB}$$
$$T_{incr} = 8\;\textrm{hours}$$

Calculating the number of storage accounts:
$$\implies N_{stacc}= \frac{1024}{60\cdot 3200} \cdot \sqrt{\frac{50\cdot 1000 \cdot 125}{8}}$$
$$ \approx 4.714\quad \mathbf{\approx 5}\; \textbf{storage accounts}\quad \textrm{(rounded to full integer)}$$

Calculating the number of worker instances:
$$W_{veeam} = \frac{1024}{60} \cdot \sqrt{\frac{V_{veeam}^{incr}\cdot N_{vm}}{T_{incr} \cdot \psi_{worker}}}$$

$$W_{veeam} = \frac{1024}{60} \cdot \sqrt{\frac{50\cdot 1000}{8 \cdot 125}}$$
$$\approx 120.68\quad \mathbf{\approx 121}\; \textbf{worker instances}\quad \textrm{(rounded to full integer)}$$
