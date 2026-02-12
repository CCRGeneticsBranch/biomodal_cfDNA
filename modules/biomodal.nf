        # Biomodal
        expand(join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","bams","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.bam"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","variant_call_files","germline","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz"),sample=[SAMPLE]),

rule biomodal:
    """
    Run Biomodal evoC analysis pipeline
    """
    input:
        fastq = [join(RESULTSDIR, "biomodal", "nf-input", new) for new in manifest['New']]
    output:
        bam = join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","bams","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.bam"),
        vcf = join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","variant_call_files","germline","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz")
    params:
        sample = "{sample}",
        output = join(RESULTSDIR, "biomodal")
    envmodules:
        TOOLS["biomodal"]
    shell:
        """
        biomodal analyse --work-dir {params.output}/nf-work \
            --input-path {params.output} \
            --output-path {params.output} \
            --additional-profile super_seq \
            --tag {params.sample} --mode 6bp
        """
