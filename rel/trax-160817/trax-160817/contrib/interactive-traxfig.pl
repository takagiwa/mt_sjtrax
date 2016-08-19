#! /usr/bin/perl

while (<STDIN>){
  chomp($_);
  $rec = $rec . " '" . $_ . "'";
  $cmd_line = "traxfig". $rec;
  print "$cmd_line\n";
  system($cmd_line);
}
