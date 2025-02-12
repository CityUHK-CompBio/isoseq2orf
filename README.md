# isoseq2orf
Pipeline to convert long-read sequencing data to a representative transcriptome for a cancer type and perform primary sequence characterization of the novel ORFs.

`000_ccs2gtf.sh`: This script converted raw data from the Pacbio sequencer to the master transcriptome.

`001_gtf2orf.sh`: This script performed QC, predicted the ORFs, and performed primary sequence characterisation of the master transcriptome.

`002_gtf2qnt.sh`: This script performed quantification of the master transcriptome based on external short-read RNA-seq datasets.

`003_orf2ms.sh`: This script performed MS/MS validation of predicted novel ORFs.


