## RiseHigh
A small utility that helps when you're moving from [Highrise](https://highrisehq.com) to any other CRM or sales tool.

## Usage
`./risehigh.rb /path/to/contacts_csv_file /path/to/directory_of_contacts_text_files`

`# creates new_contacts_csv_file in same directory as original contacts_csv_file`

## Use Cases
Highrise provides [several export options](http://i.imgur.com/XmImj67.png). If you're moving to an entirely new system and you've ever added notes to anyone in Highrise, none of these is very helpful. CSV is the obvious choice for re-importing (and you can download a separate CSV for every tag you might care about), but it doesn't include Highrise "notes".

So, you donwload all notes and emails as a .zip file, and it unzips into a directory containing a text file for each person in the database. These text files structured with YAML, and include all the contact's details as well as a YAML node for each note that has been added to the contact.

If you have thousands of contacts, manually going through to see which contacts have notes and then copy/pasting them either into the CSV or into your new CRM really sucks. So you either need a new intern or you can just use this script.

It's not fancy. It's not even very good ruby. But it works to solve this particular problem.

## Details
### Inputs
The script requires two command line arguments (in this order):
* The path to the CSV file you want to add notes to
* The path to the directory where all the YAML text files are

### Output
The script writes a new CSV file next to the old one with `new_` appended to the beginning of the file name. This CSV file will be identical to the original, but with a new `Notes` column appended onto the end. (It doesn't matter how many or which other columns exist, so feel free to use Highrise's "streamlined" export option.)

For rows in the CSV where the value in the `Name` column matches one or more filenames in the directory you specify, the correct file will be matched using the Highrise ID, and then any notes in that text file will be added to the `Notes` column, delimited by newlines and some asterisks.

It doesn't need the YAML files directory to be a 1:1 match to rows in the CSV. So feel free to "Download all notes and emails (.zip)" for your entire database, and then export CSVs for each segment or subset you need. Then run the script on each CSV separately, pointing to the same directory of YAML files, and it will find matches and do its thing.

### Programmer Talent Level
I've tested it with a ~5,000 record CSV and it takes about 10 seconds to run. It could probably be a lot more efficient, and if you have tens or hundreds of thousands of contacts you might run out of memory. I believe there is a way to use Ruby's CSV library to create an enumerator instead of holding the entire array in memory. If you figure this out, pull requests are welcome.

### Mailchimp Notes
By default, it skips notes automatically inserted by Mailchimp. You can change this by setting `discard_mailchimp_notes = false` at the top of `risehigh.rb`. If your database doesn't have any Mailchimp notes, this setting won't do anything.

## Contributing
Pull requests are welcome. 

It's GPLv2, so please push improvements back upstream.
