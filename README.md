# SingleSampleGenotyping_BW

## Introduction
These two scripts for the Blue Waters supercomputer conduct single-sample genotyping on GVCF files (GenotypeGVCFs_SingleSample_BW.sh) or on realigned, recalibrated bam files (bcftools_SingleSample_BW). In contrast to joint genotyping, variant calling and genotyping is done separately on each sample. Each output VCF is merged into a multi-sample VCF containing the separately called genotypes for a given cohort. Most researchers recommend the joint genotyping approach because its use of population-wide information increases sensitivity (particularly for low-frequency variants) and accuracy; however, single-sample genotyping offers a useful comparison because it may capture some variants (especially those unique to a single sample) discarded by the joint genotyping method (see https://gatkforums.broadinstitute.org/gatk/discussion/4150/should-i-analyze-my-samples-alone-or-together).

## GenotypeGVCFs_SingleSample_BW.sh
This script uses GATK's GenotypeGVCFs command to separately genotype each single-sample GVCF file output by HaplotypeCaller. The *--includeNonVariantSites* flag is set so that all sites present in the bed file (which in this case contains all exonic intervals) are genotyped; this step is required to distinguish between missing data and homozygous reference genotypes. The output of GenotypeGVCFs is piped to an *awk* command that removes any sites not covered by at least one read, and a compressed VCF is written to disk. Ten samples (i.e. ten commands) are placed on each node.

The syntax to run the script is
*bash GenotypeGVCFs_SingleSample_BW.sh \<reference assembly to use: hg19 or hg38> \<path to Batch directory containing single-sample GVCFs> \<output directory; will be created if doesn't exist>*

For example:
*bash GenotypeGVCFs_SingleSample_BW.sh hg19 /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/BWA/GATK_HC/ADSP_Batch1.BWA_GATK_defaults /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleGenotyping/hg19/BWA/GATK-HC_defaults/Batch1*

## bcftools_SingleSample_BW.sh
This script uses the *mpileup* and *call* commands from bcftools to call variants on and genotype realigned, recalibrated bam files. **bcftools mpileup** is used to generate a pileup of read bases from which **bcftools call** identifies variants. By default all sites are output, allowing distinction between missing data and homozygous reference genotypes. As with the GenotypeGVCFs analog of this script, the output is piped to an *awk* command that removes any sites not covered by at least one read, and a compressed VCF is written to disk. Ten samples (i.e. ten commands) are placed on each node.

The syntax to run the script is
*bash GenotypeGVCFs_SingleSample_BW.sh \<reference assembly to use: hg19 or hg38> \<path to Batch directory containing realigned, recalibrated bams> \<output directory; will be created if doesn't exist>*

For example:
*bash bcftools_SingleSample_BW.sh hg19 /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/BWA/GATK_HC/ADSP_Batch1.BWA_GATK_defaults /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleGenotyping/hg19/BWA/bcftools_defaults/Batch1*





