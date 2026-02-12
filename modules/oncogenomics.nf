       # OpenCravat
        expand(join(RESULTSDIR, "OpenCravat", "{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz.tsv"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "OpenCravat", "{sample}.all_annotations.txt"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "OpenCravat", "{sample}.rare_annotation.tsv"),sample=[SAMPLE]),

rule opencravat:
    """
    Run OpenCravat 2.13.0 on VCF files
    """
    input:
        vcf = join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","variant_call_files","germline","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz")
    output:
        variants = join(RESULTSDIR, "OpenCravat", "{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz.tsv")
    params:
        output = join(RESULTSDIR, "OpenCravat")
    threads:
        getthreads("opencravat")-1
    shell:
        """
        echo "Running OpenCRAVAT 2.13.0 analysis"
        echo "Input VCF: {input.vcf}"
        echo "Genome build: hg38 (GRCh38)"
        echo "Annotators: gnomad3, gnomad4"

        /data/khanlab/projects/ngs_pipeline_testing/opencravat/oc_vg_2.13_install/bin/oc run \
        {input.vcf} \
        -l hg38 \
        -a gnomad3 \
        --mp {threads} \
        -t text \
        --md /data/khanlab/projects/ngs_pipeline_testing/opencravat/oc_vg_2.13_install/lib/python3.9/site-packages/cravat/modules \
        -d {params.output}
        """

rule filter_variants:
    """
    Filter OpenCravat output
    """
    input:
        variants = join(RESULTSDIR, "OpenCravat", "{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz.tsv")
    output:
        all_output = join(RESULTSDIR, "OpenCravat", "{sample}.all_annotations.txt"),
        rare_output = join(RESULTSDIR, "OpenCravat", "{sample}.rare_annotation.tsv")
    params:
        sample = "{sample}"
    shell:
        """
        python /data/khanlab/projects/Nextflow_dev/dev/vg_dev/Oncogenomics_NF_WF/bin/filter_opencravat_output.py \
                --sample-id {params.sample} \
                --all-output {output.all_output} \
                --rare-output {output.rare_output} \
                --maf-cutoff 0.05 \
                {input.variants}
        """