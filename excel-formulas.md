---
title: Azure Backup Cost Calculation
---

## General Parameters

Parameter | Unit | Default   | Description
:---------|:----:|----------:|:------------------------------------------------------------------------------------------------------------
$P_{veeam}$ | \% | 50\% | Veeam Data Reduction (in percent subtracted from original volume)
$P_{azure}$ | \% | 0\% | Azure Data Reduction (in percent subtracted from original volume)
$\Delta_{daily}$ | \% | 3.0\% | Daily change rate (average for all workloads)
$\beta_{veeam}$ | kB | 1024 kB |  Veeam blocksize (read at source)
$\psi_{worker}$ | MB/s | 90 MB/s | Maximum throughput of a single Veeam worker (depends on worker VM size: 90, 180 or 270 MB/s)
$\psi_{stacc}$ | MB/s | 3200 MB/s | Maximum throughput of a single Azure blob storage account (25 or 60 Gb/s $\implies$ 3200 or 7680 MB/s)

***

### Azure Cost Parameters

These depend on chosen region, VM size, storage tier, reserved vs. pay-as-you-go, etc., and should be selectable from Azure cost tables. The given defaults are just examples from *WestEurope* region.

Parameter              | Unit                                  | Default                           | Description
:----------------------|:--------------------------------------|----------------------------------:|:---------------------------------------------------------------------------------------------------------------------------------
$D_{azure}$ | \%                                               | $0\%$   | Azure discount percentage
$C_{azure}^{storage}$ | \$ per GB per month                    | *(hot RA-GRS payg)* 0.04900 \$ | Azure blob storage (used as Veeam backup target) cost per GB per month
$C_{azure}^{vault}$ | \$ per GB per month                      | *(RA-GRS)* 0.05696 \$ | Azure backup vault (used as Azure backup target) cost per GB per month
$C_{azure}^{vm}$ | \$ per hour                                 | *(Std_F4s_v2 payg)* 0.22700 \$   | Azure VM cost per hour
$C_{azure}^{snap}$ | \$ per GB per month                       | 0.13020 \$ | Azure **VM snapshot** cost per GB per month
$C_{azure}^{backupsnap}$ | \$ per GB per month                 | 0.14500 \$ | Azure **backup snapshot** cost per GB per month
$C_{azure}^{put}$ | \$ per $10,000$                            | *(hot tier)* 0.10800 \$ | Cost of $10,000$ Azure API *put* calls
$C_{azure}^{backup(small)}$ | \$ per VM                        | 5 \$ | Monthly cost of Azure backup service per VM of provisioned size $<50$ GB
$C_{azure}^{backup(medium)}$ | \$ per VM                       | 10 \$ | Monthly cost of Azure backup service per VM of provisioned size $\geq50$ GB and $<500$ GB
$C_{azure}^{backup(addon)}$ | \$ per VM per $500$ GB           | 10 \$ | Monthly add-on cost in steps of $500$ GB for Azure backup service per VM of provisioned size $\geq500$ GB

***

### Veeam Cost Parameters

Constant                      | Unit                    | Default  | Description
:-----------------------------|:-----------------------:|---------:|:---------------------------------------------------------------------------------------------------
$D_{veeam}$ | \%                        | 30\%     | Veeam discount percentage
$C_{veeam}^{list}$   | \$ per VM per month | 10.85 \$ | VUL list price ($=1.302,00$ \$ per $10$ VMs per year)
$C_{veeam}^{real} = C_{veeam}^{list} \cdot ( 1 - D_{veeam})$ | \$ per VM per month | 7.60 \$  | Real (i.e. discounted) VUL cost per VM per month

***

## Main Input variables

Variable | Unit    | Description                             | Constraints
:--------|:-------:|:----------------------------------------|---------------------------------
$N_{vm}^{small}$ | | Number of small VMs $<50$ GB
$N_{vm}^{medium}$ | | Number of medium VMs $\geq50$ GB and $<500$ GB
$N_{vm}^{large}$ | | Number of large VMs $\geq500$ GB
$N_{vm}$ | | Total number of VMs to be protected | $=N_{vm}^{small}+N_{vm}^{medium}+N_{vm}^{large}$
$V_{vm}$ | GB | Average provisoned size of VMs to be protected
$U_{vm}$ | \% | Average disk utilization of protected VMs
$T_{incr}$ | hours | Time window for incremental backups
$R_{days}$ | days | Retention
$N_{snaps}$ | | Number of daily snapshots to be kept | must be $\geq2$
$\delta_{isfull}$ | | Does first Azure native snapshot require full (used) size ? | $1=$ yes \| $0=$ no

***

## Calculation Formulas

### General

Value                    |         |    | Formula
-------------------------|--------:|:--:|--------------------
Total provisioned source volume of workloads in TB (all VMs) | $V_{prov}$ | $=$ | $\big(N_{vm}\cdot V_{vm}\big)\div 1024$
Total used source volume (average) of workloads in TB (all VMs) | $V_{used}$ | $=$ | $V_{prov}\cdot U_{vm}$
Total snapshot volume in TB (if $\delta_{isfull}=0$) | $V_{snaps}$ | $=$ | $V_{used}\cdot\Delta_{daily}\cdot N_{snaps}$
Total snapshot volume in TB (if $\delta_{isfull}=1$) | $V_{snaps}$ | $=$ | $\Big(V_{used}\cdot\Delta_{daily}\cdot(N_{snaps}-1)\Big)+V_{used}$

***

### Veeam Backup

Value                    |         |    | Formula
-------------------------|--------:|:--:|--------------------
Volume of full backups in TB (all VMs) | $V_{veeam}^{full}$ | $=$ | $(1-P_{veeam})\cdot V_{used}$
Volume of incremental backups in TB (all VMs) | $V_{veeam}^{incr}$ | $=$ | $V_{veeam}^{full}\cdot\Delta_{daily}$
Total backup volume in TB for retention of $r$ days (no GFS, all VMs) | $V_{veeam}^{total}(r)$ | $=$ | $V_{veeam}^{full}+ \big(V_{veeam}^{incr} \cdot(r-1)\big)$
Throughput required for incremental backup in MB/s | $\Phi_{incr}$ | $=$ | $\big(V_{veeam}^{incr}\cdot 1024^2\big)\div\big(T_{incr}\cdot 3600\big)$
Veeam workers required for incremental backup<br/>$\quad$rounded up to full integer | $N_{workers}$ | $=$ | $\Phi_{incr}\div\psi_{worker}$
Estimated number of API *put* calls within given $r$ days<br/>$\quad$ incrementals only | $A_{put}(r)$ | $=$ | $(r\cdot V_{veeam}^{incr}\cdot 1024^3)\div\beta_{veeam}$
Maximum number of Veeam workers per storage account in MB/s<br/>$\quad$ rounded up to full integer, based on storage account limit given as $\psi_{stacc}$ | $N_{workers_{max}}(\psi_{stacc})$ | $=$ | $\psi_{stacc}\div\psi_{worker}$
Number of storage accounts required in MB/s<br/>$\quad$ rounded up to full integer, based on storage account limit given as $\psi_{stacc}$ | $N_{stacc}(\psi_{stacc})$ | $=$ | $\textrm{max}\Big((\Phi_{incr}\div\psi_{stacc}),(N_{workers}\div N_{workers_{max}})\Big)$

***

### Azure Backup

Value                    |         |    | Formula
-------------------------|--------:|:--:|--------------------
Volume of full backups in TB (all VMs) | $V_{azure}^{full}$ | $=$ | $(1-P_{azure})\cdot V_{used}$
Volume of incremental backups in TB (all VMs) | $V_{azure}^{incr}$ | $=$ | $V_{azure}^{full}\cdot\Delta_{daily}$
Total backup volume in TB for retention of $r$ days (no GFS, all VMs) | $V_{azure}^{total}(r)$ | $=$ | $V_{azure}^{full}+ \big(V_{azure}^{incr} \cdot(r-1)\big)$
Cost of Azure Backup service for all small VMs $<50$ GB | $C_{azure}^{small}$ | $=$ | $N_{vm}^{small}\cdot C_{azure}^{backup(small)}$
Cost of Azure Backup service for all medium VMs $\geq50$ GB and $<500$ GB | $C_{azure}^{medium}$ | $=$ | $N_{vm}^{medium}\cdot C_{azure}^{backup(medium)}$
Cost of Azure Backup service for all large VMs $\geq500$ GB | $C_{azure}^{large}$ | $=$ | $N_{vm}^{large}\cdot C_{azure}^{backup(large)}$
Total cost of Azure Backup service for all VMs | $C_{azure}^{total}$ | $=$ | $C_{azure}^{small}+C_{azure}^{medium}+C_{azure}^{large}$
Monthly total cost of Azure backup vault storage for all VMs with retention of $r$ days | $C_{azurevault}^{total}(r)$ | $=$ | $V_{azure}^{total}(r)\cdot C_{azure}^{vault}\cdot 1024$
