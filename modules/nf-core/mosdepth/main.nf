process MOSDEPTH {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mosdepth:0.3.8--hd299d5a_0' :
        'biocontainers/mosdepth:0.3.8--hd299d5a_0' }"

    input:
    tuple val(meta), path(bam), path(bai), path(bed)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path('*.global.dist.txt')      , emit: global_txt
    tuple val(meta), path('*.summary.txt')          , emit: summary_txt
    tuple val(meta), path('*.region.dist.txt')      , emit: regions_txt   , optional:true
    tuple val(meta), path('*.per-base.d4')          , emit: per_base_d4   , optional:true
    tuple val(meta), path('*.per-base.bed.gz')      , emit: per_base_bed  , optional:true
    tuple val(meta), path('*.per-base.bed.gz.csi')  , emit: per_base_csi  , optional:true
    tuple val(meta), path('*.regions.bed.gz')       , emit: regions_bed   , optional:true
    tuple val(meta), path('*.regions.bed.gz.csi')   , emit: regions_csi   , optional:true
    tuple val(meta), path('*.thresholds.bed.gz')    , emit: thresholds_bed, optional:true
    tuple val(meta), path('*.thresholds.bed.gz.csi'), emit: thresholds_csi, optional:true
    path 'versions.yml'                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--fasta ${fasta}" : ""
    def interval = bed ? "--by ${bed}" : ""
    if (bed && args.contains("--by")) {
        error "'--by' can only be specified once when running mosdepth! Either remove input BED file definition or remove '--by' from 'ext.args' definition"
    }
    if (!bed && args.contains("--thresholds")) {
        error "'--thresholds' can only be specified in conjunction with '--by'"
    }

    """
    mosdepth \\
        --threads ${task.cpus} \\
        ${interval} \\
        ${reference} \\
        ${args} \\
        ${prefix} \\
        ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mosdepth: \$(mosdepth --version 2>&1 | sed 's/^.*mosdepth //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.global.dist.txt
    touch ${prefix}.summary.txt
    touch ${prefix}.region.dist.txt
    touch ${prefix}.per-base.d4
    echo "" | gzip > ${prefix}.per-base.bed.gz
    touch ${prefix}.per-base.bed.gz.csi
    echo "" | gzip > ${prefix}.regions.bed.gz
    touch ${prefix}.regions.bed.gz.csi
    echo "" | gzip > ${prefix}.thresholds.bed.gz
    touch ${prefix}.thresholds.bed.gz.csi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mosdepth: \$(mosdepth --version 2>&1 | sed 's/^.*mosdepth //; s/ .*\$//')
    END_VERSIONS
    """
}
