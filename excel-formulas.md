# Documentation of the Azure Cost Calculation (presented at TechExpo 2023)

## General Parameters

Parameter | Unit | Default | Description
--- | --- | ---: | ---
$P_{veeam}$ | % | $50\%$ | Veeam Data Reduction (in percent subtracted from original volume)
$P_{azure}$ | % | $0\%$ | Azure Data Reduction ( in percent subtracted from original volume)
$\Delta_{daily}$ | % | $3.0\%$ | Daily change rate (all workloads)
$D_{veeam}$ | % | $30\%$ | Veeam discount percentage
$D_{azure}$ | % | $0\%$ | Azure discount percentage
$\beta_{veeam}$ | kB |1024 kB |  Veeam blocksize (read at source)
$\psi_{worker}$ | MB/s | 90 MB/s | Maximum throughput of a single Veeam worker (depends on woker size: 90, 180 or 270 MB/s)
$\psi_{stacc}$ | MB/s | 3200 MB/s | Maximum throughput of a single Azure blob storage account (25 or 60 Gb/s $\implies$ 3200 or 7680 MB/s)

## Main Input variables

Variable | Unit | Description
--- | --- | ---
$N_{vm}$ | - | Number of native Azure VMs to protect
$V_{vm}$ | GB | Average provisoned size of VMs to be protected
$U_{vm}$ | %| Average Disk utilization of protected VMs
$T_{incr}$ | hours | Time window for incremental backups
$R_{days}$ | days | Retention
$N_{snaps}$ | - | Number of daily snapshots to be kept (must be $\geq1$)
$\delta_{isfull}$ | - | does first Azure native snapshot require full occupied size ? ($1=yes; 0= no$)

## Veeam Backup Volume Calculation

Formula / Function | Description
--- | ---
$V_{prov}= \big(N_{vm} \cdot V_{vm}\big) \div {1024}$| Total source volume of workloads [TB] (provisioned)
$V_{used}= V_{prov} \cdot U_{vm}$| Total source volume of workloads [TB] (used)
$V_{incr} = (1-P_{veeam}) \cdot V_{used} \cdot \Delta_{daily} $ | Single incremental backup volume [TB]
$V_{total} = \Big(1-P_{veeam}\Big) \cdot \Big(V_{used} + \big((V_{used} \cdot \Delta_{daily}) \cdot (R_{days}-1)\big)\Big)$ | Total backup volume [TB] (i.e. one full plus $(R_{days}-1)$ incremental backups)
$V_{snaps} = V_{used} \cdot \Delta_{daily} \cdot N_{snaps}$ | Total snapshot volume [TB] (if $\delta_{isfull}=0$)
$V_{snaps} = \Big(V_{used} \cdot \Delta_{daily} \cdot (N_{snaps}-1)\Big) + V_{used}$ | Total snapshot volume [TB] (if $\delta_{isfull}=1$)
$\Phi_{incr} = \big(V_{incr} \cdot 1024^2\big) \div \big(T_{incr} \cdot 3600 \big)$ | Throughput required for incremental backup [MB/s]
$N_{workers} = \Phi_{incr} \div \psi_{worker}$ | Veeam workers required for incremental backup (rounded up to integer)
$A_{put}(days) = \big(days \cdot \Delta_{daily} \cdot V_{used}  \cdot 1024^3\big) \div \beta_{veeam} $ | Estimated number of *API put* calls within $days$ (incrementals only).
$N_{workers_{max}}(\psi) = \psi \div \psi_{worker}$ | Maximum number of Veeam workers per storage account, based on storage account limit given as $\psi$ in MB/s
$N_{stacc}(\psi) = \mathrm{max}\big((\Phi_{incr} \div \psi) , (N_{workers} \div N_{workers_{max}})\big)$ | Number of storage accounts required, based on storage account limit given as $\psi$ in MB/s
