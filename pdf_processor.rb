require 'pdf-reader'
require 'fileutils'
require 'find'
require 'logger'
require 'yaml'

CONFIG_FILE = 'config.yml'
@config = nil
@logger = nil

def main
  #TODO: allow users to pass in arguments for specified config file, or file to process, etc
  set_config
  pdfs = gather_pdfs_from_base_directory
  successfully_written_pdfs = write_pdfs_text_to_new_file(pdfs)
end

def write_pdfs_text_to_new_file(pdfs)
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
end

def write_document_info(text_file, pdf_reader)
  text_file.write("PDF_VERSION: #{pdf_reader.pdf_version}\n")
  text_file.write("PDF_INFO: #{pdf_reader.info}\n")
  text_file.write("PDF_METADATA: #{pdf_reader.metadata}\n")
  text_file.write("PDF_PAGE_COUNT: #{pdf_reader.page_count}\n")
end

def get_text_file(pdf)
  text_file_path = @config['text_results_base_directory']
  File.dirname(pdf).split('/').each do |subdirectory|
    text_file_path = text_file_path + subdirectory
    Dir.mkdir(text_file_path) unless Dir.exists?(text_file_path)
  end
  text_file_path = text_file_path + File.basename(pdf).split('.')[0] + '.txt'
  File.open(text_file_path, 'w')
end

def gather_pdfs_from_base_directory
  pdfs = []
  Find.find($config['process_queue_base_directory']) do |path|
    pdfs << path if path.match(/.*\.pdf$/)
  end
  pdfs
end

def set_config
  if !(File.exists?(File.join(__dir__, CONFIG_FILE)))
    fail "Config file '#{File.join(__dir__, CONFIG_FILE)}' does not exist!"
  end
  @config = YAML::load_file(File.join(__dir__, CONFIG_FILE))
  @logger = Logger.new(@config['log_file')).level = Logger::INFO
end

main
