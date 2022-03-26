#!/bin/bash
#shellcheck disable=2155

readonly VERSION=0.1

bold=$(tput bold)
normal=$(tput sgr0)

PROGRAMNAME=mace

working_dir=$(pwd)

array=(valgrind gdb gcc make)
doing="$(echo $1 | tr '[:upper:]' '[:lower:]')"
opt2=$2

NL="\n"


function check_dependencies {    
        local passed=0;    
    
        for i in "${array[@]}"    
        do    
                if ! hash $i >/dev/null 2>&1 ; then    
                        passed=1    
                        echo -ne "$i - Not Found    
Please install it and run it again"     
                fi    
        done    
        if [ $passed -gt 0 ]; then    
                exit    
        fi    
}


function write_main {
	echo -n "#include <stdio.h>

int main(int argc, char** argv){
	printf(\"Hello World$NL\");
	printf(\"Number of arguments: '%d'\\nProgram ran: '%s'$NL\",argc,argv[0]);
	return 0;
}

">$opt2/src/main.c
}


function write_make {
	echo -ne "SOURCE=./src
ODIR=./obj

PROGS=$opt2


GITGUD= -march=native -O3  -pipe -D_GNU_SOURCE -fomit-frame-pointer
DEBUG=-O0 -Wextra -g
MEMLEAK=-ggdb  -fno-omit-frame-pointer -fsanitize=undefined

CC=gcc
CFLAGS = \$(DEBUG) -pedantic -Wall -std=c99 -lm

DEPS=\$(wildcard \$(SOURCE)/*.h)

SOURCES=\$(wildcard \$(SOURCE)/*.c)

SOURCES_OBJ=\$(subst .c,.o,\$(subst src,obj,\$(SOURCES)))

print-% : ; @echo \$* = \$(\$*)

\$(ODIR)/%.o : \$(SOURCES) \$(DEPS)
	@ mkdir -p \$(ODIR)
	\$(CC) \$(CFLAGS) -c -o \$@ \$<

program: \$(SOURCES_OBJ)
	\$(CC) \$(CFLAGS) \$(SOURCES_OBJ) -o \$(PROGS)

debug: \$(SOURCES_OBJ) \$(MY_LIBS_OBJ)
	\$(CC) \$(CFLAGS) \$(DEBUG) \$(SOURCES_OBJ) -o \$(PROGS)

memleak: \$(SOURCES_OBJ) \$(MY_LIBS_OBJ)
	\$(CC) \$(MEMLEAK) \$(CFLAGS)  \$(SOURCES_OBJ) -o \$(PROGS)

clean:
	rm \$(ODIR) -r
	rm \$(PROGS)

run:
	./\$(PROGS)

gdb:
	gdb \$(PROGS)

val:
	valgrind --leak-check=full --track-origins=yes --verbose ./\$(PROGS)

" > $opt2/Makefile
}


function write_help_run {
	echo -ne "$PROGRAMNAME PROJECT <HELP>

${bold}Commands:${normal}

	${bold}DEFAULT${normal} |> Runs by default with no need of extra input.

	${bold}DEBUG${normal}	|> Runs the program in debug mode (Low Compiler Optimization) for easy error checking.

	${bold}MEMLEAK${normal} |> Runs the program with memory leak specific flag for that specific purpouse.
	
	${bold}CLEAN${normal}	|> Removes all files created with make.
	
	${bold}HELP${normal}	|> Shows this specific menu.
"
}


function write_help {
	echo -ne "${bold}The C project.${normal}
${bold}Usage:${normal}
	$PROGRAMNAME [new|compile|project] <NAME>

${bold}HELP:${normal}
		
	${bold}NEW${normal} 	 |> Needs a NAME to create the project folder.
		    It wil create a new directory with the project name.

	${bold}COMPILE${normal}  |> Compiles the project and creates a «compile_commands.json»
		    It can be disabled with the flag '--no_json'.

	${bold}PROJECT${normal}	 |> Compiles the project and runs the program.
		    It has other running modes. Do <${bold}MACE PROJECT HELP${normal}> to list the different modes.
"
}


function __run_main__ {
	check_dependencies

	if [[ $doing == "new" ]]; then
		mkdir $opt2 $opt2/src
		write_make
		write_main
		echo "Project ${bold}$opt2${normal} was created"

	elif [[ $doing == "compile" ]]; then
		flag="$(echo $opt2 | tr '[:upper:]' '[:lower:]')"	
		if hash bear >/dev/null 2>&1;
		then
			case $flag in
				--no_json)
					(make)
					;;
				*)
					(bear -- make)
					;;
			esac
		else
			(make)
		fi

	elif [[ $doing == "project" ]]; then
		flag="$(echo $opt2 | tr '[:upper:]' '[:lower:]')"
		case $flag in
			help)
				write_help_run
				;;
			debug)
				(make debug && make gdb)
				;;
			memleak)
				(make memleak && make val)
				;;
			clean)
				(make clean)
				;;
			*)
				(make program && make run)
				;;
		esac
	else
		write_help
		exit
	fi
}

__run_main__
