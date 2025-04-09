#!/usr/bin/env ruby
# frozen_string_literal: true

require 'zip'

@build_jdk_version = nil
@build_tools = nil

@target_java_version = Set.new

def bytes_to_int(bytes)
  bytes.each_with_index.inject(0) do |sum, (byte, index)|
    sum + byte * 256**(bytes.length - index - 1)
  end
end

BUILD_WITH_JDK_SPEC_LABEL = 'Build-Jdk: '

CREATED_BY_SPEC_LABEL = 'Created-By: '

def examine_meta_inf(entry)
  entry.get_input_stream.read.each_line do |line|
    if line.start_with? BUILD_WITH_JDK_SPEC_LABEL
      @build_jdk_version = line.split(BUILD_WITH_JDK_SPEC_LABEL).last.strip
    elsif line.start_with? CREATED_BY_SPEC_LABEL
      @build_tools = line.split(CREATED_BY_SPEC_LABEL).last.strip
    end
  end
end

def examine_bytecode_version(entry)
  header = entry.get_input_stream.read(8).bytes
  minor_version = bytes_to_int(header[4...6])
  major_version = bytes_to_int(header[6...8])
  @target_java_version.add "#{major_version}.#{minor_version}"
end

def poke_jar(jar)
  Zip::File.open(jar) do |zip_file|
    zip_file.each do |entry|
      if entry.name == 'META-INF/MANIFEST.MF'
        examine_meta_inf(entry)
      elsif entry.name.end_with? '.class'
        examine_bytecode_version(entry)
      end
    end
  end

  puts "Summary: #{jar}"
  puts "was built with JDK #{@build_jdk_version} and #{@build_tools}"
  puts "Bytecode version is: #{@target_java_version.to_a.join(', ')}"
end

ARGV.map { poke_jar _1 }
