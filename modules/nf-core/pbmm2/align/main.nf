process PBMM2_ALIGN {
    tag "$meta.id"
    label 'process_high'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbmm2:1.14.99--h9ee0642_0':
        'biocontainers/pbmm2:1.14.99--h9ee0642_0' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // pbmm2 doesn't support .fna extension — compute the .fa name in Groovy
    def fasta_name = fasta.name
    def fa_ref = fasta_name.endsWith('.fna.gz') ? fasta_name[0..-8] + '.fa.gz' :
                 fasta_name.endsWith('.fna')    ? fasta_name[0..-5] + '.fa'    : fasta_name
    def needs_rename = fa_ref != fasta_name

    """
    ${needs_rename ? "ln -s \$(readlink -f ${fasta_name}) ${fa_ref}" : ''}

    pbmm2 \\
        align \\
        $args \\
        $fa_ref \\
        $bam \\
        ${prefix}.bam \\
        --num-threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbmm2: \$(pbmm2 --version |& sed '1!d ; s/pbmm2 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbmm2: \$(pbmm2 --version |& sed '1!d ; s/pbmm2 //')
    END_VERSIONS
    """
}
