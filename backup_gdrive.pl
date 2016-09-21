#!/usr/bin/perl

sub find_first_file_id;
sub extract_filename;

# List of files to backup
# (directories and files, no trailing /, has to have leading /)
my @to_backup = (
  "/srv",
  "/etc/nginx",
  "/etc/init.d/dorade-api",
  "/etc/iptables.conf",
  "/etc/network/if-up.d/firewall"
);

# Path to the gdrive executable
my $gdrive = "gdrive";

foreach $path (@to_backup) {
  if (-e $path) {
    my $id = &find_first_file_id($path);
    if (-d $path) {
      if ($id) {
        # Sync
        print "Syncing $path...\n";
        my $res = `$gdrive sync upload --keep-local --delete-extraneous --no-progress $path $id`;
        if ($? != 0) {
          print "Error syncing directory $path.\n";
        }
      } else {
        # New upload
        print "Uploading directory $path...\n";
        # We need to create the directory first:
        my $fname = &extract_filename($path);
        my $res = `$gdrive mkdir $fname`;
        if ($res =~ /Directory\s+(\w+)\s+created/) {
          # Get the new directory ID from the output:
          print "Created new distant directory $1\n";
          $res = `$gdrive sync upload --no-progress $path $1`;
          if ($? == 0) {
            print $res . '\n';
            next;
          }
        }
        print "Gdrive returned error for initial sync of directory.\n";
      }
    } else {
      if ($id) {
        # We're using update
        print "Updating file $path...\n";
        my $res = `$gdrive update --no-progress $id $path`;
        if ($? != 0) {
          print "Error updating file $path.\n";
        }
      } else {
        # We're using upload
        print "Uploading file $path...\n";
        my $res = `$gdrive upload --no-progress $path`;
        if ($? != 0) {
          print "Error uploading file $path.\n";
        }
      }
    }
  }
}

exit 0;

sub extract_filename {
  my $path = shift(@_);
  # Isolate the filename:
  if ($path =~ /^\/(.+\/)*(.+)$/) {
    return $2;
  }
  return '';
}

sub find_first_file_id {
  my $path = shift(@_);
  my $fname = &extract_filename($path);
  if ($fname) {
    my @ret = `$gdrive list -q "name = '$fname'"`;
    if (scalar(@ret) > 1) {
      # We got a file.
      # Parse ID from the second line:
      if ($ret[1] =~ /^(\w+)\s+/) {
        return $1;
      }
    }
  }
}
