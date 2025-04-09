#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'net/http'

# Make sure you've imported GPG keys in advance.
#   wget -O KEYS https://dist.apache.org/repos/dist/release/flink/KEYS && gpg --import KEYS

VERBOSE = false
DEFAULT_TMP_DIR = './tmp'

def sh(*cmd)
  joined_cmd = cmd.join(' ')
  puts "=> #{joined_cmd}" if VERBOSE
  output = `#{joined_cmd}`
  puts output if VERBOSE && !output.empty?
  output
end

def ensure_exists(*commands)
  commands.each do |command|
    abort "No #{command} command found." if `which #{command}`.empty?
  end
end

def download(url, path = DEFAULT_TMP_DIR)
  url.split('/').last.then do |filename|
    sh 'wget', '--quiet', '-O', "#{path}/#{filename}", url
  end
end

def verify_binary(file, path = DEFAULT_TMP_DIR)
  actual_sha_result = sh('sha512', "#{path}/#{file}").split(' = ').last.strip
  expected_sha_result = sh('cat', "#{path}/#{file}.sha512").split.first.strip

  if actual_sha_result == expected_sha_result
    puts "✅ SHA512 of #{file} matches."
  else
    abort "❌ SHA512 mismatch for #{file}."
  end

  gpg_verify_result = sh 'gpg', '--verify', '--output', '-', "#{path}/#{file}.asc", "#{path}/#{file}", '2>&1',
                         '>/dev/null'
  if gpg_verify_result.include? 'Good signature'
    puts "✅ GPG signature of #{file} is valid."
    puts "   #{gpg_verify_result.split('Good signature from "').last.split('"').first}"
  else
    abort "❌ Invalid GPG signature found for #{file}."
  end
end

ensure_exists 'wget', 'sha512', 'gpg'

sh 'rm', '-rf', './tmp'
sh 'mkdir', '-p', './tmp'

def validate_url(link)
  result = Net::HTTP.get(URI(link))
  doc = Nokogiri::HTML(result)
  header = doc.xpath('/html/head/title').text

  puts "===== Verifying #{header} ====="

  artifacts = []
  nested_packages = []

  doc.xpath('/html/body/ul/li[*]/a').each do |item|
    item_text = item.text
    next if item_text == '..'

    if item_text.end_with? '/'
      nested_packages << item_text
    elsif !item_text.end_with? '.asc', '.sha512'
      artifacts << item_text
    end
  end

  # recursively validate nested packages
  nested_packages.each { validate_url link + _1 }

  artifacts.each do |artifact|
    download "#{link}#{artifact}"
    download "#{link}#{artifact}.asc"
    download "#{link}#{artifact}.sha512"

    verify_binary artifact
  end
end

ARGV.map { validate_url _1 }
