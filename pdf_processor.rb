# encoding: utf-8

# This module is used to take a .pdf file and extract its raw text into
# a .txt file.
#
# Main functions:
#
#   process_pdf(pdf_source, options = { ... })
#   process_dir(pdf_source, options = { ... })
#
# Example usage:
#
#   PDFToTextFile.process_pdf('/home/user/sample.pdf')
#   PDFToTextFile.process_dir('/home/user/myPDFs/')
#
# Options:
#
#         log_file  -  If specified, this is the location where a log file
#                      will be placed, tracking the process.
#
#        text_dest  -  If specified, this is the directory where the resulting
#                      text file(s) will be placed. If not specified, the
#                      resulting text files will be placed in the same path as
#                      the pdf(s)
#
#     text_dir_dup  -  If set to true, and text_dest is specified and
#                      process_dir is called, any subfolder structure in the
#                      pdf_source directory will be duplicated in the text_dest
#
#     archive_dest  -  If specified, this is the directory where the pdf(s)
#                      will be moved to if they are successfully converted to
#                      text files.
#
#   arhive_dir_dup  -  If set to true, and arhive_dest is specified and
#                      process_dir is called, any subfolder structure in the
#                      pdf_source directory will be duplicated in the
#                      archive_dest.

module PDFToTextFile

  include 'dir'
  include 'file'
  include 'fileutils'
  include 'find'
  include 'logger'
  include 'pdf-reader'
  include 'yaml'

  OPTION_KEYS = { text_dir_dup:   'text_dir_dup',
                  text_dest:      'text_dest',
                  arhive_dest:    'archive_dest',
                  arhive_dir_dup: 'archive_dir_dup',
                  log_file:       'log_file' }

  attr_accessor :pdf_source, :options, :logger

  def process_pdf(pdf_source, options = {})
    @pdf_source = pdf_source
    @options = options
    validate_pdf_options
    process_pdf_with_options
  end

  def process_dir(pdf_source, options = {}
    @pdf_source = pdf_source
    @options = options
    validate_options
    process_dir_with_options
  end

  def validate_options
    fail "Could not locate pdf_source: #{@pdf_source}" unless File.exists?(@pdf_source)
    if !@options[:text_dest].nil? && !File.exists?(@options[:text_dest])
      fail "Could not locate text_dest: #{@options[:text_dest]}"
    end
    if !@options[:archive_dest].nil? && !File.exists?(@options[:archive_dest])
      fail "Could not locate archive_dest: #{@options[:archive_dest]}"
    end
    @logger = Logger.new(@options[:log_file]) unless @options[:log_file].nil?
  end

  def process_pdf_with_options
    pdfs = gather_pdfs_from_base_directory
    successfully_written_pdfs = write_pdfs_to_text_files(pdfs)
    archive_select_files_from_dir(successfully_written_pdfs,
                                  @config['process_queue_base_directory'],
                                  @config['archive_base_directory'])
  end


  def archive_select_files_from_dir(files, dir, archive)
    files.each do |file|
      archive_path = archive + get_file_subpath(dir, file)
      FileUtils.mkdir_p(archive_path)
      FileUtils.mv(file, archive_path)
    end
  end

  def write_pdfs_to_text_files(pdfs)
    written_pdfs = []
    pdfs.each do |pdf|
      begin
        write_pdf_text(pdf)
        written_pdfs << pdf
      rescue StandardError => e
        @logger.error("Can't process #{pdf}")
        @logger.error(e)
      end
    end
    written_pdfs
  end

  def write_pdf_text(pdf)
    text_file = get_text_file(pdf)
    pdf_reader = PDF::Reader.new(pdf)
    write_document_info(text_file, pdf_reader)
    pdf_reader.pages.each { |page| text_file.write(page.text) unless page.text.strip.empty? }
    text_file.close
  end

  def write_document_info(text_file, pdf_reader)
    text_file.write("PDF_VERSION: #{pdf_reader.pdf_version}\n")
    text_file.write("PDF_INFO: #{pdf_reader.info}\n")
    text_file.write("PDF_METADATA: #{pdf_reader.metadata}\n")
    text_file.write("PDF_PAGE_COUNT: #{pdf_reader.page_count}\n")
  end

  def get_text_file(pdf)
    text_file_path = @config['text_results_base_directory'] + get_file_subpath(@config['process_queue_base_directory'], pdf) + '/'
    FileUtils.mkdir_p(text_file_path)
    text_file = text_file_path + File.basename(pdf).split('.')[0] + '.txt'
    File.open(text_file, 'w')
  end

  def get_file_subpath(origin_path, file_path)
    origin_base = origin_path.split('/').last
    if origin_base.empty? then fail "Cannot get subpath from: #{origin_path}" end
    file_sub_path = file_path.split(origin_base)[1]
    File.dirname(file_sub_path)
  end

  def duplicate_subdirectory_structure(origin_dir, dest_dir)
    origin_base = origin_dir.split('/').last
    if original_base.empty? then fail "Cannot duplicate directory: #{original}" end
      Find.find(original) do |path|
        if File.directory?(path)
          subdir = path.split(original_base)[1]
          subdir.nil? ?  FileUtils.mkdir_p(copy + '/') : FileUtils.mkdir_p(copy + subdir)
        end
      end
  end

  def gather_pdfs_from_base_directory
    pdfs = []
    Find.find(@config['process_queue_base_directory']) do |path|
      pdfs << path if path.match(/.*\.pdf$/)
    end
    pdfs
  end


  def main
 end

end
