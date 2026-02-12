log.info """\
Biomodal cfDNA
=============
NF version   : $nextflow.version
runName      : $workflow.runName
username     : $workflow.userName
configs      : $workflow.configFiles
profile      : $workflow.profile
cmd line     : $workflow.commandLine
start time   : $workflow.start
projectDir   : $workflow.projectDir
launchDir    : $workflow.launchDir
workDir      : $workflow.workDir
homeDir      : $workflow.homeDir
samplesheet  : ${params.samplesheet}
sample       : ${params.sample} // Sample name, e.g. CL0338-cfD-M
genome       : ${params.genome} // Reference genome, e.g. hg38
"""
.stripIndent()

Channel
  .fromPath(params.samplesheet)
  .splitCsv(header: true, sep: '\t')
  .map { row -> [original: row.Original, new: row.New] }
  .set { ROWS }

ROWS
  .map { v -> tuple(v.original, v.new) } 
  .set { fastq_mapping }

ROWS
  .map { it.new }
  .set { fastqs }

include { FASTQC } from "./modules/biomodal.nf"
include { BWA_MEM } from './modules/ichorCNA.nf'
include { ICHOR_CNA } from './modules/ichorCNA.nf'

process link_raw {
    //Link fastqs from storage to Biomodal nf-input, renaming multiple flowcells as lanes

    input:
    tuple path(original), val(new)

    output:
    tuple path(biomodal/nf-input/new)

    script:
    """
    ln -s ${fastq_mapping[0]} biomodal/nf-input/${fastq_mapping[1]}
    """
}

workflow {
    fastq_mapping | link_raw
}

workflow.onComplete {
    println "Workflow finished at: ${workflow.end}"
    println: "Sample processed: ${params.sample}" 
}