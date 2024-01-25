---
title: Azure Backup Cost Calculation
---

## General Parameters

Parameter | Unit | Default   | Description
:---------|:----:|----------:|:------------------------------------------------------------------------------------------------------------
$P_{veeam}$ | \% | 50\% | Veeam Data Reduction (in percent subtracted from original volume)
$P_{azure}$ | \% | 0\% | Azure Data Reduction ( in percent subtracted from original volume)
$\Delta_{daily}$ | \% | 3.0\% | Daily change rate (all workloads)
$\beta_{veeam}$ | kB | 1024 kB |  Veeam blocksize (read at source)
$\psi_{worker}$ | MB/s | 90 MB/s | Maximum throughput of a single Veeam worker (depends on worker VM size: 90, 180 or 270 MB/s)
$\psi_{stacc}$ | MB/s | 3200 MB/s | Maximum throughput of a single Azure blob storage account (25 or 60 Gb/s $\implies$ 3200 or 7680 MB/s)

### Azure Cost Parameters

These depend on chosen region, VM size, storage tier, reserved vs. pay-as-you-go, etc., and should be selectable from Azure cost tables. The given defaults are just examples from *WestEurope* region.

Parameter   | Unit                                              | Default | Description
:-----------|:--------------------------------------------------|--------:|:---------------------------------------------------------------------------------------------------------------------------
$D_{azure}$ | \%                                                | $0\%$   | Azure discount percentage
$C_{azure}^{storage}$ | \$ per GB per month                     | *(hot RA-GRS payg)* 0.04900 \$ | Azure blob storage (used as Veeam backup target) cost per GB per month
$C_{azure}^{vault}$ | \$ per GB per month                       | *(RA-GRS)* 0.05696 \$ | Azure backup vault (used as Azure backup target) cost per GB per month
$C_{azure}^{vm}$ | \$ per hour                                  | *(Std_F4s_v2 payg)* 0.22700 \$   | Azure VM cost per hour
$C_{azure}^{snap}$ | \$ per GB per month                        | 0.13020 \$ | Azure **VM snapshot** cost per GB per month
$C_{azure}^{backupsnap}$ | \$ per GB per month                  | 0.14500 \$ | Azure **backup snapshot** cost per GB per month
$C_{azure}^{put}$ | \$ per 10,000                               | *(hot tier)* 0.10800 \$ | Cost of 10,000 Azure API *put* calls
$C_{azure}^{backup(small)}$ | \$ per VM (<50 GB)                | 5 \$ | Monthly cost of Azure backup service per VM of provisioned size <50 GB
$C_{azure}^{backup(medium)}$ | \$ per VM  (>50 GB and < 500 GB) | 10 \$ | Monthly cost of Azure backup service per VM of provisioned size between 50 GB and 500 GB
$C_{azure}^{backup(addon)}$ | \$ per VM per 500 GB              | 10 \$ | Monthly add-on cost in steps of 500 GB for Azure backup service per VM of provisioned size >500 GB

This allows us to calculate the total (non-discounted) monthly cost of the Azure backup service for a single *large* VM with provisioned size given as $V_{vm}$ (>500 GB)

> $C_{azure}^{backup(large)}(V_{vm})=C_{azure}^{backup(medium)}+\Big(C_{azure}^{backup(addon)}\cdot(\textrm{roundup}\Big({\frac{V_{vm}}{\textrm{500 GB}}}\Big)-1)\Big)$

### Veeam Cost Parameters

Constant    | Unit                      | Default  | Description
:-----------|:-------------------------:|---------:|:----------------------------------------------------------------------------------------------------------
$D_{veeam}$ | \%                        | 30\%     | Veeam discount percentage
$C_{veeam}^{list}$   | \$ per VM per month | 10.85 \$ | VUL list price (1.302,00 \$ per 10 VMs per year)
$C_{veeam}^{real} = C_{veeam}^{list} \cdot ( 1 - D_{veeam})$ | \$ per VM per month | 7.60 \$  | discounted VUL cost

## Main Input variables

Variable | Unit | Description
:-----------------|:----:|:-----------------------------------------------------------------------------
$N_{vm}$          | | Number of native Azure VMs to protect
$V_{vm}$          | GB | Average provisoned size of VMs to be protected
$U_{vm}$          | \% | Average Disk utilization of protected VMs
$T_{incr}$        | hours | Time window for incremental backups
$R_{days}$        | days | Retention
$N_{snaps}$       | | Number of daily snapshots to be kept (must be $\geq1$)
$\delta_{isfull}$ | | does first Azure native snapshot require full occupied size ? ($1=yes; 0= no$)

## Calculation Formulas

### Veeam

Total provisioned source volume of workloads in TB:\
$\quad V_{prov}=\big(N_{vm}\cdot V_{vm}\big)\div 1024$

Total used source volume of workloads in TB:\
$\quad V_{used}=V_{prov}\cdot U_{vm}$

Volume of a single incremental backup in TB:\
$\quad V_{incr}=(1-P_{veeam})\cdot V_{used}\cdot\Delta_{daily}$

Total backup volume in TB ($=$ single full backup plus $(R_{days}-1)$ incremental backups): \
$\quad V_{total}=\Big(1-P_{veeam}\Big)\cdot\Big(V_{used}+\big((V_{used}\cdot\Delta_{daily})\cdot(R_{days}-1)\big)\Big)$

Total snapshot volume in TB  (if $\delta_{isfull}=0$):\
$\quad V_{snaps}=V_{used}\cdot\Delta_{daily}\cdot N_{snaps}$

Total snapshot volume [TB] (if $\delta_{isfull}=1$):\
$\quad V_{snaps}=\Big(V_{used}\cdot\Delta_{daily}\cdot(N_{snaps}-1)\Big)+V_{used}$

Throughput required for incremental backup in MB/s:\
$\quad\Phi_{incr}=\big(V_{incr}\cdot 1024^2\big)\div\big(T_{incr}\cdot 3600\big)$

Veeam workers required for incremental backup (rounded up to full integer):\
$\quad N_{workers}=\Phi_{incr}\div\psi_{worker}$

Estimated number of API *put* calls within given $days$ (incrementals only):\
$\quad A_{put}(days)=\big(days\cdot\Delta_{daily}\cdot V_{used}\cdot 1024^3\big)\div\beta_{veeam}$

Maximum number of Veeam workers per storage account (rounded up to integer), based on storage account limit given as $\psi$ in MB/s:\
$\quad N_{workers_{max}}(\psi_{stacc})=\psi_{stacc}\div\psi_{worker}$

Number of storage accounts required (rounded up to integer), based on storage account limit given as $\psi$ in MB/s:\
$\quad N_{stacc}(\psi_{stacc})=\textrm{max}\Big((\Phi_{incr}\div\psi_{stacc}),(N_{workers}\div N_{workers_{max}})\Big)$
