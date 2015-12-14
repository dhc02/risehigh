#!/usr/bin/env ruby

#############
# Author: Donnie Clapp
#############

#############
# Config
#
# Set this to true to discard notes automatically inserted into Highrise by Mailchimp
# Set it to false to copy all notes to CSV, including Mailchimp notes
discard_mailchimp_notes = true
#############

require 'csv'
require 'yaml'

def print_instructions
  puts "\n*****"
  puts "** Well, that didn't work."
  puts "**"
  puts "** Use it like this:"
  puts "** ./risehigh.rb /path/to/old_contacts_CSV /path/to/old_contacts_YAML_files_directory"
  puts "*****\n\n"
end

# show help if the arguments don't seem right
# i.e., if there aren't two args or the second one isn't a directory
if ARGV.length != 2 || !File.directory?(ARGV[1])
  print_instructions
  exit
end

old_contacts_file = File.absolute_path(ARGV[0])
old_contacts_file_basename = File.basename(old_contacts_file)
export_path = File.absolute_path(File.dirname(old_contacts_file))

old_contacts_yaml_dir = File.absolute_path(ARGV[1])

# create array of file names, which are full names plus some other stuff
old_contacts_yaml_file_names = Dir.entries(old_contacts_yaml_dir)
# trim array items to just the full name by throwing away everything after the -
old_contacts_yaml_file_names.map! { |file_name| file_name = file_name.split('-')[0] }

# read the old contacts file and assign contents to the old_contacts array
old_contacts = CSV.read(old_contacts_file, headers:true)

# start a new_contacts array with the headers of the old_contacts_file plus a new "notes" column
new_contacts = []
headers = old_contacts.headers
headers << "Notes"
new_contacts << headers

Dir.chdir(old_contacts_yaml_dir)
puts ""
suspected_duplicates = 0
unmatched_contacts = []
# for each old contact, add notes if they exist from YAML files
old_contacts.each do |row|
  # find files in the old_contacts_yaml_dir whose names match the current row's
  # contact name
  contact_name = row['Name']
  contact_id = row[0]
  # we have to convert ", :, and / in contact names to _ because that's what
  # Highrise does when it creates the YAML files
  name_matching_string = contact_name.gsub('"','_')
  name_matching_string = name_matching_string.gsub('/','_')
  name_matching_string = name_matching_string.gsub(':','_')
  matching_files=Dir.glob(name_matching_string + "*") # => an array

  suspected_duplicates = suspected_duplicates+1 if matching_files.length > 1

  # duplicate contacts mean we have to verify the ID in the YAML file matches the ID in the CSV row.
  # If they match, we search for notes and add them to the new_contacts row
  # If they don't, we go to the next file that matches the name and see if the IDs match
  # We break the for loop after we find a matching ID
  for file in matching_files
    yaml = YAML.load_file(file)
    # puts "contact id: #{contact_id}  |  YAML ID: #{yaml[0]["ID"]}"
    if yaml[0]["ID"].to_s == contact_id
      contact_has_a_note = false
      yaml_notes = ""
      # We don't know how many notes there are in the YAML file, if any. So we have to
      # iterate over each top-level item in the YAML and see if it's a note
      yaml.each do |item|
        item_name = item.keys[0]
        if item_name.include?("Note")
          contact_has_a_note = true
          note_author = item[item_name][0]["Author"]
          note_time = item[item_name][1]["Written"]
          note_body = item[item_name][3]["Body"]
          is_mailchimp_note = note_body.include?("Has not purchased.")
          # we're going to (optionally) ignore Mailchimp notes about emails opened.
          # If it doesn't look like a note from Mailchimp, then we add it to the
          # yaml_notes string with some light text formatting and tell the
          # console we're making progress
          unless is_mailchimp_note && discard_mailchimp_notes
            yaml_notes << "Note from #{note_author} #{note_time}\r***\r#{note_body}\r*******************\r"
            puts "Adding #{item_name} to #{contact_name} (#{contact_id})"
          end #unless
        end #if
      end #yaml.each

      puts "No notes found for #{contact_name}." unless contact_has_a_note
      # exit for loop and stop searching;
      # we found a file with a matching ID and took notes from it
      break
    end #if
  end #for

  # this shouldn't ever happen so let's print to console if it does
  if matching_files.length == 0
    puts "No matching YAML file for #{contact_name}"
    unmatched_contacts << contact_name
  end

  # add built up yaml_notes string to end of row we're currently working on
  row << yaml_notes
  # add modified row to new_contacts array
  new_contacts << row
end #each

# write the new_contacts.csv file from the new_contacts array
Dir.chdir(export_path)
CSV.open("new_#{old_contacts_file_basename}", 'w') do |file|
  new_contacts.each do |row|
    file << row
  end
end

puts "\n**********"
puts "Your new contacts CSV has been placed at #{export_path}/new_#{old_contacts_file_basename}."
puts "**********\nNote: There are #{suspected_duplicates.to_s} suspected duplicate contacts! WTF?" if suspected_duplicates > 0
if unmatched_contacts.length > 0
  puts "**********\nNote: There were #{unmatched_contacts.length.to_s} people who couldn't be matched to a file in the directory. Which is weird."
  unmatched_contacts.each do |name|
    puts name
  end
end
puts "**********"
puts "Have a great day."
puts "**********"
