// Import generic module functions
include { saveFiles; getSoftwareName } from './functions'

params.options = [:]

/*
 * Download SRA data via parallel-fastq-dump
 */
process SRA_FASTQ_DUMP {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::parallel-fastq-dump=0.6.6" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/parallel-fastq-dump:0.6.6--py_1"
    } else {
        container "quay.io/biocontainers/parallel-fastq-dump:0.6.6--py_1"
    }
    
    input:
    tuple val(meta), val(fastq)

    output:
    tuple val(meta), path("*fastq.gz"), emit: fastq
    tuple val(meta), path("*log")     , emit: log

    script:
    id         = "${meta.id.split('_')[0..-1].join('_')}"
    paired_end = meta.single_end ? "" : "--readids --split-e"
    rm_orphan  = meta.single_end ? "" : "[ -f  ${id}.fastq.gz ] && rm ${id}.fastq.gz"    
    """
    parallel-fastq-dump \\
        --sra-id $id \\
        --threads $task.cpus \\
        --outdir ./ \\
        --tmpdir ./ \\
        --gzip \\
        $paired_end \\
        > ${id}.fastq_dump.log
    $rm_orphan
    """
}
