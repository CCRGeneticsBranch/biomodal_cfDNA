         # ichorCNA
        expand(join(RESULTSDIR, "ichorCNA", "{sample}.10000.wig"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "ichorCNA", "{sample}.params.txt"),sample=[SAMPLE])

rule hmmcopy:
    """
    Generate WIG file from biomodal evoC bam
    """
    input:
        bam = join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","bams","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.bam"),
    output:
        wig = join(RESULTSDIR, "ichorCNA", "{sample}.10000.wig")
    params:
        window = 10000
    shell:
        """
        /data/khanlab3/gb_omics/software/hmmcopy_utils/bin/readCounter \
                --window {params.window} --quality 20 \
                --chromosome "chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY" \
                {input.bam} > {output.wig}
        """

rule ichorCNA:
    """
    Run ichorCNA on WIG file
    """
    input:
        wig = join(RESULTSDIR, "ichorCNA", "{sample}.10000.wig")
    output:
        purity = join(RESULTSDIR, "ichorCNA", "{sample}.params.txt")
    params:
        ichor_scripts = config["ichorCNA_scripts"],
        ichor_extdata = config["ichorCNA_extdata"],
        outdir = join(RESULTSDIR, "ichorCNA"),
        sample = "{sample}"
    envmodules:
        TOOLS["R"]
    shell:
        """
        Rscript {params.ichor_scripts}/runIchorCNA.R --id {params.sample} \
            --WIG {input.wig} --ploidy 'c(2,3)' --normal 'c(0.5,0.6,0.7,0.8,0.9,0.95,0.99)' --maxCN 5  \
            --gcWig {params.ichor_extdata}/gc_hg38_10kb.wig \
            --mapWig {params.ichor_extdata}/map_hg38_10kb.wig \
            --centromere {params.ichor_extdata}/GRCh38.GCA_000001405.2_centromere_acen.txt \
            --includeHOMD True --chrs 'c(1:22, \"X\")' --chrTrain 'c(1:22)' --normalizeMaleX True \
            --estimateNormal True --estimatePloidy True --estimateScPrevalence True \
            --scStates 'c(1,3)' --txnE 0.9999 --txnStrength 10000 --outDir {params.outdir}
            #--normalPanel {params.ichor_extdata}/HD_ULP_PoN_hg38_500kb_median_normAutosome_median.rds \
        """