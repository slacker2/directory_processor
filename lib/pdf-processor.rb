# encoding: utf-8
#
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
#          log_file  -  If specified, this is the location where a log file
#                       will be placed, tracking the process.
#
#         text_dest  -  If specified, this is the directory where the resulting
#                       text file(s) will be placed. If not specified, the
#                       resulting text files will be placed in the same path as
#                       the pdf(s)
#
#      text_dir_dup  -  If set to true, and text_dest is specified and
#                       process_dir is called, any subfolder structure in the
#                       pdf_source directory will be duplicated in the text_dest
#
#      archive_dest  -  If specified, this is the directory where the pdf(s)
#                       will be moved to if they are successfully converted to
#                       text files.
#
#   archive_dir_dup  -  If set to true, and arhive_dest is specified and
#                       process_dir is called, any subfolder structure in the
#                       pdf_source directory will be duplicated in the
#                       archive_dest.

module PDFToTextFile
  require 'pdf-reader'
  if File.exists?('./file-processor.rb')
    require './file-processor'
  else
    require File.dirname(File.absolute_path(__FILE__)) + '/file-processor'
  end

  module_function
  def process_pdf(pdf_source, options = {})
    fail "File is not a pdf: #{pdf_source}" unless File.extname(pdf_source) == '.pdf'
    FileProcessor.process_file(pdf_source, method(:get_pdf_text), options)
    process_pdf_with_options(pdf_source)
  end

  def process_dir(pdf_source, options = {})
    FileProcessor.process_dir(pdf_source, method(:get_pdf_text), options)
  end

  def get_pdf_text(pdf)
    return nil unless File.extname(pdf) == '.pdf'
    pdf_text = ''
    puts pdf
    pdf_reader = PDF::Reader.new(pdf)
    prepend_document_info(pdf_text, pdf_reader)
    pdf_reader.pages.each do |page|
      pdf_text << page.text
    end
    pdf_text
  end

  def prepend_document_info(text_string, pdf_reader)
    text_string << ("PDF_VERSION: #{pdf_reader.pdf_version}\n")
    text_string << ("PDF_INFO: #{pdf_reader.info}\n")
    text_string << ("PDF_METADATA: #{pdf_reader.metadata}\n")
    text_string << ("PDF_PAGE_COUNT: #{pdf_reader.page_count}\n")
    puts text_string
  end
end

