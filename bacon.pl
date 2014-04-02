#!/usr/bin/perl

#Created by Ernesto Barajas
#University of Texas at Austin
#Requires the IMDB database and Perl 

#variables used for breadth first search
my %graph;
my %actors;
#variables used for populating
my $currentActor = "";
my $tempActor;
my $tempMovie;

# #Opening Actors List
# print "Opening Actors Database...\n";
# open FILEACTORS, 'zcat actors.list.gz |' or print "ERROR - Could not open Actors List";


print ("Building Actors/Actresses List...\n");
foreach my $file (@ARGV) {
	print "Opening $file...\n";
	open FILEACTORS, "zcat $file |" or print "ERROR - Could not open file";
	#Skipping all the header junk
	$_ = <FILEACTORS>;
	$_ = <FILEACTORS> until /^\-+\t/;
	while(<FILEACTORS>) {
		#remove new line character
		chomp;

		#skip if blank line
		if ($_ eq "") {
			next;
		}

		#using a regex to seperate the line into different variables
		if (/^([^\t]*)\t+(.+?\([\d]+\))(.+)/) {	
			#checks if the actor field is blank
			#which means the movie belongs to the previous actor
			if ($1 eq "") {
				#checks if we need to skip the entry, since it's not a movie, or just archive footage
				if ($2 =~ /^\"/ || $3 =~ /\(TV\)/ || $3 =~ /\(V\)/ || $3 =~ /\(VG\)/ || /archive footage/i) {
					next;
				}
				#else push the movie onto the actors anonymous array of movie he has starred in
				push (@{$graph{$currentActor}}, $2);
				
				#if the current movie doesn't have an entry in the hash, create one
				#and have it's value be an anonymous array with the current actor inside 
				if (!(exists $graph{$2})) {
					$graph{$2} = [$currentActor];
				}
				
				#else, it already exists, so add the actor onto the movie's actor list
				else {
					push (@{$graph{$2}}, $currentActor);
				}
			}
			#if going into this else
			#program has gone to a new actor
			else {
				#set the currentActor variable to the new actor
				$currentActor = $1;
				#add the actor onto the actor list 
				#which is used to search for actors name when they're not specfic
				$actors{$currentActor} = 1;
				
				#again, skip the entry if it's anything but a movie
				if ($2 =~ /^\"/ || $3 =~ /\(TV\)/ || $3 =~ /\(V\)/ || $3 =~ /\(VG\)/ || $3 =~ /archive footage/i) {
					next;
				}

				#create an entry for the new actor
				#with an anonymous array that contains his movie
				$graph{$currentActor} = [$2];

				#same check if movie has an entry
				if (!(exists $graph{$2})) {
					$graph{$2} = [$currentActor];
				}
				else {
					push (@{$graph{$2}}, $currentActor);
				} 
			}
		}
	}	
}
close FILEACTORS or warn "Error closing file";


#more variables needed for breadth first search;
my %visited;
my %parent;
my @queue;
my $size;

#starting breadth first search
#adding kevin bacon onto the queue
unshift(@queue, "Bacon, Kevin (I)");
$size = @queue;
print "Building the Bacon Matrix...\n";

#Breadth-First Search:
#searches for the shortest path to every actor and movie node
#saves if the node as been visited to save time
#saves the node's parent for use in backtracking
while ($size != 0) {
	my $currentNode = pop (@queue);
	foreach my $node (@{$graph{$currentNode}}) {
		if (!exists $visited{$node}) {
			$visited{$node} = 1;
			$parent{$node} = $currentNode;
			unshift (@queue, $node);
		}
		$size = @queue;
	}		
}

#sets kevin bacon's parent to null and sets him to visited
#comes into play when we do the backtracking
$parent{"Bacon, Kevin (I)"} = "null";
$visited{"Bacon, Kevin (I)"} = 1;

print("Ready!\n");
print(">");
my $searchTemp;
while (<STDIN>) {
	chomp;
	exit 0 if ($_ eq "");
	$searchTemp = $_;
	print("Searching...\n");

	#if the actor exists, but he wasn't visited in the breadth first search
	#he doesn't have a connection to kevin bacon (e.g Van Halen, Edward)
	if (exists $actors{$searchTemp} && !(exists $visited{$searchTemp})) {
		print "Zero Degress of Kevin Bacon. Sadness\n";
		print "\n>";
		next;
	}	

	#checks for a complete match with an actor
	#if there is none, search for possible matches
	if (!(exists ($graph{$searchTemp}))) {
		
		#just in case the name is entered in as FirstName LastName, instead of LastName, FirstName
		#swaps the names and checks if it exists in the graph
		#if it does, goes to the backtrack part of the search
		my $possibleTerm = join(', ', reverse(split(' ', $searchTemp, 2)));
		if (exists $graph{$possibleTerm}) {
			$searchTemp = $possibleTerm;
			goto search;
		}

		#else, it takes it in as seperate keywords
		my @keywords = split(/[,\s]/, $searchTemp);
		my @possibleMatches;
		
		#if there's more than one keyword, we need to 
		#check to see that the possible matches all 
		#match the keywords
		#partial matches on keywords are ignored
		if ((scalar @keywords) > 1) {
			
			#basically grep each keyword on the actors list
			@possibleMatches = grep(/\b$keywords[0]\b/i, keys %actors);
			foreach my $word (@keywords) {
				@possibleMatches = grep(/\b$word\b/i, @possibleMatches)
			}

			#if there's nothing in the possibleMatches array
			#print nothing found
			if ((scalar @possibleMatches == 0)) {
				print "No actor/actress found. :("
			}

			#else, check if there's more than one match
			elsif ((scalar @possibleMatches) > 1) {
				print "Did you mean?...\n";
				sort @possibleMatches;
				foreach my $match (@possibleMatches) {
					print "'$match'\n";
				}
			}

			#if not, that means there's only one match
			#and we take that to be the actors name
			#and go to the backtrack part of the search
			else {
				#set the search term to the match
				$searchTemp = $possibleMatches[0];
				#skip the next statement at the end of the if statement
				#and jump to the backtrack part of the search
				goto search;
			}	
		}

		#search if there's only one keyword
		else {
			#basically the same premise as the above search
			#but only with one keyword
			@possibleMatches = grep(/\b$searchTemp\b/i, keys %actors);
			if ((scalar @possibleMatches) > 1) {
				print "Did you mean?...\n";
				foreach my $match (@possibleMatches) {
					print "'$match'\n";
				}
			}
			elsif (scalar @possibleMatches == 0) {
				print "No actor/actress found. :(\n";
			}
			else {
				$searchTemp = $possibleMatches[0];
				goto search;
			}
		}
		print "\n>";
		next;
	}
	search:
	#backtrack from the search term to kevin bacon
	my $searchNode = $searchTemp;
	my $baconNumber = 0;
	print "$searchNode\n";
	until ($parent{$searchNode} eq "null") {
		$searchNode = $parent{$searchNode};
		if ($searchNode =~ /\(\d{4}\)\s*$/) {
			print "\t$searchNode\n";
		}
		else {
			print "$searchNode\n";
			$baconNumber++;
		}
	}
	print "Bacon Number: $baconNumber";
	print "\n>";
}

