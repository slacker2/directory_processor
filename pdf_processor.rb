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
    validate_options
    fail "File is not a pdf: #{@pdf_source}" unless File.extname(@pdf_source) == '.pdf'
    process_pdf_with_options(@pdf_source)
  end

  def process_dir(pdf_source, options = {})
    @pdf_source = pdf_source
    @options = options
    validate_options
    fail "Argument is not a directory: #{@pdf_source}" unless File.directory?(@pdf_source)
    process_dir_with_options
  end

  def validate_options
    fail 'You must specify a filename or directory.' if @pdf_source.nil?
    fail "Could not locate pdf_source: #{@pdf_source}" unless File.exists?(@pdf_source)
    if !@options[:text_dest].nil? && !File.exists?(@options[:text_dest])
      fail "Could not locate text_dest: #{@options[:text_dest]}"
    end
    if !@options[:archive_dest].nil? && !File.exists?(@options[:archive_dest])
      fail "Could not locate archive_dest: #{@options[:archive_dest]}"
    end
    @logger = Logger.new(@options[:log_file]) unless @options[:log_file].nil?
  end

  def process_pdf_with_options(pdf)
    write_pdf_text(pdf)
    archive_pdf(pdf) unless @options[:archive_dest].nil?
  end

  def process_dir_with_options
    pdfs = find_pdfs_in_dir(@pdf_source)
    written_pdfs = write_pdfs_texts(pdfs)
    @logger.debug("#{written_pdfs.size}/#{pdfs.size} pdfs written")
    written_pdfs.each { |pdf| archive_pdf(pdf) }
  end

  def archive_pdf(pdf)
    archive_path = @options[:archive_dest] + pdf_subpath(pdf)
    FileUtils.mkdir_p(archive_path)
    FileUtils.mv(pdf, archive_path)
  end

  def write_pdfs_texts(pdfs)
    written_pdfs = []
    pdfs.each do |pdf|
      begin
        write_pdf_text(pdf)
        written_pdfs << pdf
      rescue StandardError => e
        raise e if @logger.nil?
        @logger.error("Can't process #{pdf}\n#{e}")
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
    text_file_name = File.basename(pdf, '.pdf') + '.txt'
    text_file_path = text_file_path(pdf)
    FileUtils.mkdir_p(text_file_path)
    text_file = text_file_path + '/' + text_file_name
    File.open(text_file, 'w')
  end

  def text_file_path(pdf)
    options[:text_dir].nil? ? File.dirname(pdf) : options[:text_dir] + pdf_subpath(pdf)
  end

  def pdf_subpath(pdf)
    return '/' if @options[:text_dir_dup] != true || pdf == @pdf_source
    origin_base = File.basename(@pdf_source)
    File.dirname(pdf).split(origin_base)[1] || '/'
  end

  def find_pdfs_in_dir(dir)
    pdfs = []
    Find.find(dir) do |path|
      pdfs << path if path.match(/.*\.pdf$/)
    end
    pdfs
  end
end
