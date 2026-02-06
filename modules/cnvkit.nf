rule cnvkit:
    """
    Run CNVkit on biomodal evoC bam files with flat reference
    """
    input:
        bam = join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","bams","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.bam"),
    output:
        png = join(RESULTSDIR, "cnvkit", "{sample}.genome.GRCh38Decoy_primary_assembly.dedup-scatter.png")
    envmodules:
        TOOLS["cnvkit"],
        TOOLS["samtools"]
    params:
        output = join(RESULTSDIR, "cnvkit"),
        fasta = config[genome]['fasta'],
        refflat = config[genome]['refflat']
    threads:
        getthreads("cnvkit")
    shell:
        """
        cnvkit.py batch {input.bam} -n -p {threads} -m wgs --fasta {params.fasta} --output-dir {params.output} --annotate {params.refflat} --scatter
        """