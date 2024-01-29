# Azure Backup Cost Calculation

## Azure General Parameters

Parameter | Unit | Default   | Description
:---------|:----:|----------:|:------------------------------------------------------------------------------------------------------------
$R_{azure}$ | $\%$ | $100\%$ | Azure Backup Data Reduction (volume size after reduction in percent of original volume)
$\psi_{stacc}$ | MB/s | $3,200$ MB/s | Maximum throughput of a single Azure blob storage account (25 or 60 Gb/s $\implies$ 3200 or 7680 MB/s)

## Veeam Infrastructure Parameters

Parameter | Unit | Default   | Description
:---------|:----:|----------:|:------------------------------------------------------------------------------------------------------------
$R_{veeam}$ | $\%$ | $50\%$ | Veeam Data Reduction (volume size after reduction in percent of original volume)
$\beta_{veeam}$ | kB | $1024$ kB |  Veeam blocksize (read at source)
$\psi_{worker}$ | MB/s | $125$ MB/s | Maximum throughput of a single Veeam worker (depends on worker VM size: 70 - 140 MB/s)
$N_{veeam}^{max(\textrm{VBR})}$ | | $10,000$ | Maximum number of protected VMs per Veeam Backup \& Replication server
$N_{veeam}^{max(\textrm{appl})}$ | | $3,000$ | Maximum number of protected VMs per Veeam Backup for Azure appliance
$N_{veeam}^{max(\textrm{policy)}}$ | | $75$ | Maximum number of protected VMs per Veeam Backup for Azure policy
$J_{veeam}^{max(\textrm{appl)}}$ | | $300$ | Maximum number of policies per Veeam Backup for Azure appliance
$M_{veeam}^{\textrm{appl}}$ | GB | $32$ | Provisioned RAM per Veeam Backup for Azure appliance VM

***

### Azure Cost Parameters

These depend on chosen region, VM size, storage tier, reserved vs. pay-as-you-go, etc., and should be selectable from Azure cost tables. The given defaults are just examples from *WestEurope* region.

Parameter              | Unit                             | Default                                | Description
:----------------------|:---------------------------------|---------------------------------------:|:-------------------------------------------------------------------------------------------------------------------------------------
$R_{azure}$ | $\%$ | $100\%$ | Azure Backup Data Reduction (volume size after reduction in percent of original volume)
$C_{azure}^{storage}$ | \$ per GB per month               | *(hot RA-GRS payg)* 0.04900 \$ | Azure blob storage (used as Veeam backup target) cost per GB per month
$C_{azure}^{vault}$ | \$ per GB per month                 | *(RA-GRS)* 0.05696 \$ | Azure backup vault (used as Azure backup target) cost per GB per month
$C_{azure}^{vm}$ | \$ per hour                            | *(Std_F4s_v2 payg)* 0.22700 \$   | Azure VM cost per hour
$C_{azure}^{snap}$ | \$ per GB per month                  | 0.13020 \$ | Azure **VM snapshot** cost per GB per month
$C_{azure}^{backupsnap}$ | \$ per GB per month            | 0.14500 \$ | Azure **backup snapshot** cost per GB per month
$C_{azure}^{put}$ | \$ per $10,000$                       | *(hot tier)* 0.10800 \$ | Cost of $10,000$ Azure storage account API *put* calls
$C_{azure}^{backup(\textrm{small})}$ | \$ per VM                   | 5 \$ | Monthly cost of Azure backup service per VM of provisioned size $<50$ GB
$C_{azure}^{backup(\textrm{medium})}$ | \$ per VM                  | 10 \$ | Monthly cost of Azure backup service per VM of provisioned size $\geq50$ GB and $<500$ GB
$C_{azure}^{backup(\textrm{addon})}$ | \$ per VM per $500$ GB      | 10 \$ | Monthly add-on cost in steps of $500$ GB for Azure backup service per VM of provisioned size $\geq500$ GB

> **Note:** All Azure cost parameters need to be multiplied by $R_{azure}$ to get the discounted value, **also for Azure services used by the Veeam infrastructure**, given that the provided discount applies to all Azure services!

***

### Veeam Cost Parameters

Parameter                     | Unit                    | Default  | Description
:-----------------------------|:-----------------------:|---------:|:---------------------------------------------------------------------------------------------------
$D_{veeam}$ | $\%$                        | $30\%$     | Veeam discount percentage
$C_{veeam}^{list}$   | \$ per VM per month | 10.85 \$ | VUL list price ($=1.302,00$ \$ per $10$ VMs per year)
$C_{veeam}^{real} = C_{veeam}^{list} \cdot ( 1 - D_{veeam})$ | \$ per VM per month | 7.60 \$  | Real (i.e. discounted) VUL cost per VM per month

***

## Main Input variables

Variable | Unit    | Description                             | Constraints
:--------|:-------:|:----------------------------------------|---------------------------------
$\Delta_{daily}$ | $\%$ | Daily change rate (average for all workloads)
$N_{vm}^{small}$ | | Number of small VMs $<50$ GB
$N_{vm}^{medium}$ | | Number of medium VMs $\geq50$ GB and $<500$ GB
$N_{vm}^{large}$ | | Number of large VMs $\geq500$ GB
$N_{vm}$ | | Total number of VMs to be protected | $=N_{vm}^{small}+N_{vm}^{medium}+N_{vm}^{large}$
$V_{vm}$ | GB | Average provisoned size of protected VMs
$U_{vm}$ | $\%$ | Average disk utilization of protected VMs
$T_{incr}$ | hours | Time window for incremental backups
$R_{days}$ | days | Retention
$N_{snaps}$ | | Number of daily snapshots to be kept | must be $\geq2$
$\delta_{isfull}$ | | Does first Azure native snapshot require full (used) size ? | $1=$ yes \| $0=$ no

***

## Calculation Formulas

### General

Value                    |         |    | Formula
-------------------------|--------:|:--:|:--------------------
Total provisioned source volume of workloads in TB (all VMs) | $V_{prov}$ | $=$ | $\big(N_{vm}\cdot V_{vm}\big)\div 1024$
Total used source volume (average) of workloads in TB (all VMs) | $V_{used}$ | $=$ | $V_{prov}\cdot U_{vm}$
Total snapshot volume in TB (if $\delta_{isfull}=0$) | $V_{snaps}$ | $=$ | $V_{used}\cdot\Delta_{daily}\cdot N_{snaps}$
Total snapshot volume in TB (if $\delta_{isfull}=1$) | $V_{snaps}$ | $=$ | $V_{used}+\big(V_{used}\cdot\Delta_{daily}\cdot(N_{snaps}-1)\big)$
$\implies$ Total snapshot volume in TB as function of $\delta_{isfull}$ | $V_{snaps}(\delta_{isfull})$ | $=$ | $\Bigg(\big(V_{used}\cdot\Delta_{daily}\cdot N_{snaps}\big)\cdot (1-\delta_{isfull})\Bigg) + \Bigg(\Big(V_{used}+\big(V_{used}\cdot\Delta_{daily}\cdot(N_{snaps}-1)\big)\Big)\cdot\delta_{isfull}\Bigg)$

***

### Azure Backup

Value                    |         |    | Formula
-------------------------|--------:|:--:|:--------------------
Volume of full backups in TB (all VMs) | $V_{azure}^{full}$ | $=$ | $R_{azure}\cdot V_{used}$
Volume of incremental backups in TB (all VMs) | $V_{azure}^{incr}$ | $=$ | $V_{azure}^{full}\cdot\Delta_{daily}$
Total backup volume in TB for retention of $r$ days (no GFS, all VMs) | $V_{azure}^{total}(r)$ | $=$ | $V_{azure}^{full}+ \big(V_{azure}^{incr} \cdot(r-1)\big)$
Monthly cost of Azure Backup service for all small VMs $<50$ GB | $C_{azure}^{small}$ | $=$ | $N_{vm}^{small}\cdot C_{azure}^{backup(small)}$
Monthly cost of Azure Backup service for all medium VMs $\geq50$ GB and $<500$ GB | $C_{azure}^{medium}$ | $=$ | $N_{vm}^{medium}\cdot C_{azure}^{backup(medium)}$
Monthly cost of Azure Backup service for a single large VM $\geq500$ GB | $C_{azure}^{backup(large)}$ | $=$ | $C_{azure}^{backup(\textrm{addon})}\cdot \textrm{roundup}\Big(V_{vm}^{large} \div 500\textrm{GB}\Big)$
Monthly cost of Azure Backup service for all large VMs $\geq500$ GB | $C_{azure}^{large}$ | $=$ | $N_{vm}^{large}\cdot C_{azure}^{backup(large)}$
Total monthly cost of Azure Backup service for all VMs | $C_{azure}^{service}$ | $=$ | $C_{azure}^{small}+C_{azure}^{medium}+C_{azure}^{large}$
Monthly total cost of Azure Backup vault storage for all VMs with retention of $r$ days | $C_{azurevault}^{total}(r)$ | $=$ | $V_{azure}^{total}(r)\cdot C_{azure}^{vault}\cdot 1024$
Monthly total cost of Azure Backup snapshots for all VMs | $C_{azure}^{snaptotal}(\delta_{isfull})$ | $=$ | $V_{snaps}(\delta_{isfull})\cdot C_{azure}^{backupsnap}\cdot 1024$
$\implies$ Total monthly Azure Backup cost | $C_{azure}^{total}(r,\delta_{isfull})$ | $=$ | $C_{azure}^{service}+C_{azurevault}^{total}(r)+C_{azure}^{snaptotal}(\delta_{isfull})$

***

### Veeam Backup

Value                    |         |    | Formula
-------------------------|--------:|:--:|:--------------------
Volume of full backups in TB (all VMs) | $V_{veeam}^{full}$ | $=$ | $R_{veeam}\cdot V_{used}$
Volume of incremental backups in TB (all VMs) | $V_{veeam}^{incr}$ | $=$ | $V_{veeam}^{full}\cdot\Delta_{daily}$
Total backup volume in TB for retention of $r$ days (no GFS, all VMs) | $V_{veeam}^{total}(r)$ | $=$ | $V_{veeam}^{full}+ \big(V_{veeam}^{incr} \cdot(r-1)\big)$
Throughput required for incremental backup in MB/s | $\Phi_{incr}$ | $=$ | $\big(V_{veeam}^{incr}\cdot 1024^2\big)\div\big(T_{incr}\cdot 3600\big)$
Veeam workers required for incremental backup<br/>$\quad$ rounded up to full integer | $N_{workers}$ | $=$ | $\Phi_{incr}\div\psi_{worker}$
Estimated number of API *put* calls within given $r$ days<br/>$\quad$ incrementals only | $A_{put}(r)$ | $=$ | $\big(r\cdot V_{veeam}^{incr}\cdot 1024^3\big)\div\beta_{veeam}$
Maximum number of Veeam workers per storage account<br/>$\quad$ rounded up to full integer, based on storage account limit given as $\psi_{stacc}$ | $N_{maxworkers}(\psi_{stacc})$ | $=$ | $\psi_{stacc}\div\psi_{worker}$
Number of storage accounts required<br/>$\quad$ rounded up to full integer, based on storage account limit given as $\psi_{stacc}$ | $N_{stacc}(\psi_{stacc})$ | $=$ | $\textrm{max}\Big((\Phi_{incr}\div\psi_{stacc})\;,\;(N_{workers}\div N_{maxworkers})\Big)$
Appliance RAM available for policies in GB<br/>$\quad$ (e.g. $28.9$ GB for an appliance VM with $32$ GB) | $M_{veeam}^{pol}$ | $=$ | $M_{veeam}^{appl}-(M_{veeam}^{appl}\cdot 0.05) - 1.5\textrm{GB}$
Max number of VBAzure policies per appliance (based on RAM only) | $J_{veeam}^{appl(\textrm{RAM})}$ | $=$ | $1024\cdot M_{veeam}^{pol}\div \big(10 + N_{veeam}^{max(\textrm{policy})}\big)$
Resulting max number of VBAzure policies per appliance | $J_{veeam}^{appl}$ | $=$ | $\textrm{min}\Big(J_{veeam}^{max(\textrm{appl})} \; ,\; J_{veeam}^{appl(\textrm{RAM})}\Big)$
***
