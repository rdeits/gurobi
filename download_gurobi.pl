#!/usr/bin/perl

use LWP::UserAgent;
use HTML::Form;
use Term::ReadKey;
use Config;

my $filename;

if ( $ENV{'GUROBI_DISTRO'} ) {
  $filename = $ENV{'GUROBI_DISTRO'};
  print "Using GUROBI_DISTRO file $ENV{'GUROBI_DISTRO'}\n";
} else {
  my @forms;
  my $response;
  my $mech = LWP::UserAgent->new;
  $mech->cookie_jar( {} );

  while(1) {
    print "Enter your user email for gurobi.com: ";
    chomp(my $email = <>);
    print "Enter your password for gurobi.com: ";
    ReadMode('noecho');
    chomp(my $password = <>);
    ReadMode('restore');

    $response = $mech->get( "http://www.gurobi.com/account" );
    @forms = HTML::Form->parse( $response );
    
    $form = shift(@forms);  # search form
    $form = shift(@forms);  # login form
    
    $form->value('email',$email); 
    $form->value('password',$password);
    
    $response = $mech->request( $form->click );
    
    $response = $mech->get( "http://www.gurobi.com/download/gurobi-optimizer" );
    
    @forms = HTML::Form->parse( $response, "http://www.gurobi.com" );
    
    my $numforms = scalar @forms;
    if ( $numforms > 2 ) { # login failed page has two forms
      last; 
    }

    print "Login failed.  Please try again.\n";
  } 

  $form = shift(@forms);  # search form
  $form = shift(@forms);  # login form
  $form = shift(@forms);  # download form
  
  if ($^O eq 'darwin') {
      $filename = 'gurobi6.0.0_mac64.pkg'; 
  } elsif ($^O eq 'linux') {
      $filename = 'gurobi6.0.0_linux64.tar.gz'; 
  }
  
  $form->value('filename','6.0.0/'.$filename);

  print "\n Downloading $filename ... ";
  $response = $mech->request( $form->click , $filename);
#print $response->content();
  print "done\n";

  chomp($cwd = `pwd`);
  $filename = "$cwd/$filename"
}

if ($^O eq 'darwin') {
  system("mkdir","tmp");
  chdir("tmp");
  system("xar","-xf","$filename");
  chdir("gurobi600mac64tar.pkg");
  system("tar","-xvf","Payload");
  system("tar","-xvf","gurobi6.0.0_mac64.tar.gz");
  system("mv","gurobi600","../../");
  chdir("../..");
  system("rm","-rf","tmp");
#  system("rm","-rf",$filename);
} elsif ($^O eq 'linux') {
  system("tar","-xvf",$filename);
#  system("rm","-rf",$filename);
}

