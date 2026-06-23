
include { PBSV_DISCOVER     } from '../../../modules/nf-core/pbsv/discover/main'
include { PBSV_CALL         } from '../../../modules/nf-core/pbsv/call/main'
include { BCFTOOLS_INDEX    } from '../../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_VIEW     } from '../../../modules/nf-core/bcftools/view/main'


workflow BAM_SV_VARIANT_CALLING {
    take:
    sorted_bam
    sorted_bai
    fasta
    fasta_fai

    main:
    ch_versions = Channel.empty()

    //call the structural variants
    PBSV_DISCOVER(sorted_bam, fasta)
    PBSV_CALL(PBSV_DISCOVER.out.svsig, fasta)

    // Restrict to primary contigs (chr1-22,X,Y,M) and bgzip. pbsv can emit
    // records on alt/decoy/unplaced contigs (e.g. out-of-bounds positions on
    // chrUn_* contigs) that fail `bcftools index` with "end < begin". Filtering
    // them out here keeps the SV VCF indexable. Contig list is set via ext.args.
    BCFTOOLS_VIEW(PBSV_CALL.out.vcf.map { meta, vcf -> [ meta, vcf, [] ] }, [], [], [])
    BCFTOOLS_INDEX(BCFTOOLS_VIEW.out.vcf)

    vcf_ch = BCFTOOLS_VIEW.out.vcf.join(BCFTOOLS_INDEX.out.csi)

    ch_versions = ch_versions.mix(PBSV_DISCOVER.out.versions)
    ch_versions = ch_versions.mix(PBSV_CALL.out.versions)
    ch_versions = ch_versions.mix(BCFTOOLS_VIEW.out.versions)
    ch_versions = ch_versions.mix(BCFTOOLS_INDEX.out.versions)

    emit:
    vcf_ch
    versions       = ch_versions

}

