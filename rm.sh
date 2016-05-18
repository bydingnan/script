#!/bin/bash
#配置回收站最大的存储空间(字节)
#maxmemory=51200 (50M)
#maxmemory=102400 (100M)
#maxmemory=512000 (500M)
#根据情况设置为50M(对于isoa服务开发来说足够了)
maxmemory=3145728
#设置回收站所在的目录
trash=$HOME/.Trash
#设置日志文件所在的目录
mvlog=$trash/trash.log
from1=$1
from2=$2
var_pwd=
var_father=

#回收站若不存在，则新建之
if [ ! -e $trash ];then
	mkdir -p $trash
	chmod 755 $trash
fi

#产生7位的随机数
function rand()
{
	a=(0 1 2 3 4 5 6 7 8 9 a b c d e A B C D E F)
	b=''
	for ((i=0;i<7;i++))
	do
		b=${a[$RANDOM%${#a[*]}]}$b
	done
	echo $b
}

random=$(rand)

#文件不存在时的提示信息
function file_null()
{
	local file=$1
	echo "rm: cannot remove '$file': No such file or directory"
}

#打印参数出错后的提示信息
function echo_msg()
{
	echo -n "rm: missing operand
	Try 'rm --help' for more information.
	"
}

function echo_msg2()
{
	echo -n "rm: invalid option  '$1'
	Try 'rm --help' for more information.
	"
}

#回收站管理函数
function deal()
{
	local tmp=$(mktemp /tmp/tfile.XXXXXX)
	local num=$(($(cat $mvlog| wc -l)/2))
	#awk -F: -v nu=$num  -v trash=$trash '{if (NR<=nu) system("rm -rf "trash"'/'"$2"':'"$3""); \
	#else print $0}' $mvlog | sort -o $mvlog
	awk -F: -v nu=$num  -v trash=$trash '{if (NR<=nu) system("rm -rf "trash"'/'"$2"':'"$3""); \
	else print $0}' $mvlog >> $tmp
	mv $tmp $mvlog
}

JUG=
#目录处理函数
function jug_cur()
{
	local tmp=
	local dirname=$1
	local jug=${dirname/\/*/}
	if [ "$jug" == "." ];then
		var_pwd=${dirname/./$(pwd)}
		JUG=0
	elif [ "$jug" == ".." ];then
		tm=$(pwd)
		tmp=${tm%/*}   
		var_father=${dirname/../$tmp}   
		JUG=1
		#elif [ "$jug" == "~" ];then
		#return 2
	else
		JUG=2
	fi  
}

#命令不带参数时的普通文件删除函数
function rm1
{
	local filename=$(basename $from1)
	local dirname=$(dirname $from1)
	jug_cur $dirname
	if [ "$JUG" -eq 0 ];then
		dirname=$var_pwd
	elif [ $JUG -eq 1 ];then
		dirname=$var_father 
	fi 
	if [ -d "$from1" ];then
		echo "rm: cannot remove '$from1': Is a directory"
		else
		if [ ! -e $from1 ];then
			file_null $from1
		else
			echo "$dirname:$filename:$random:$(date +%Y-%m-%d.%T)" >> $mvlog
			mv "$from1" "$trash/$filename:$random"
		fi
	fi
}

#rm -i
function rmi()
{
	local filename=$(basename $from2)
	local dirname=$(dirname $from2)
	jug_cur $dirname
	if [ $JUG -eq 0 ];then
		dirname=$var_pwd
	elif [ $JUG -eq 1 ];then
		dirname=$var_father 
	fi 
	if [ -f "$from2" ];then
		echo "rm: remove regular file '$from2'?"
		read answer
		if [ "$answer" = 'y' -o "$answer" = 'Y' ];then
			echo "$dirname:$filename:$random:$(date +%Y-%m-%d.%T)" >> $mvlog
			mv "$from2" "$trash/$filename:$random"
		fi
	else
		if [ ! -e $from2 ];then
			file_null $from2
		else
			echo "rm: cannot remove '$from2': Is a directory"
		fi
	fi
}

#rm -f
function rmf()
{
	local filename=$(basename $from2)
	local dirname=$(dirname $from2)
	jug_cur $dirname
	if [ $JUG -eq 0 ];then
		dirname=$var_pwd
	elif [ $JUG -eq 1 ];then
		dirname=$var_father 
	fi 

	if [ -f "$from2" ];then
		echo "$dirname:$filename:$random:$(date +%Y-%m-%d.%T)" >> $mvlog
		mv "$from2" "$trash/$filename:$random"
	else
		if [ ! -e $from2 ];then
			:
		else
			echo "rm: cannot remove '$from2': Is a directory"
		fi
	fi
}

#rm -r
function rmr()
{
	local filename=$(basename $from2)
	local dirname=$(dirname $from2)
	jug_cur $dirname
	if [ $JUG -eq 0 ];then
		dirname=$var_pwd
	elif [ $JUG -eq 1 ];then
		dirname=$var_father 
	fi 

	if [ "$from2" = "." -o "$from2" = ".." ];then
		echo "rm: cannot remove directory: '$from2'"
	elif [ -e "$from2" ];then
		echo "$dirname:$filename:$random:$(date +%Y-%m-%d.%T)" >> $mvlog
		mv "$from2" "$trash/$filename:$random"
	else
		file_null $from2
	fi
}

#rm -rf
function rmrf()
{
	local filename=$(basename $from2)
	local dirname=$(dirname $from2)
	jug_cur $dirname
	if [ $JUG -eq 0 ];then
		dirname=$var_pwd
	elif [ $JUG -eq 1 ];then
		dirname=$var_father 
	fi 

	if [ "$from2" = "." -o "$from2" = ".." ];then
		echo "rm: cannot remove directory: '$from2'"
	elif [ -e "$from2" ];then
		echo "$dirname:$filename:$random:$(date +%Y-%m-%d.%T)" >> $mvlog
		mv "$from2" "$trash/$filename:$random"
	else
		:
	fi
}

#rm -ir
function rmir()
{
	local filename=$(basename $from2)
	local dirname=$(dirname $from2)
	jug_cur $dirname
	if [ $JUG -eq 0 ];then
		dirname=$var_pwd
	elif [ $JUG -eq 1 ];then
		dirname=$var_father 
	fi 

	if [ -e "$from2" ];then
		if [ -d "$from2" ];then
			echo -n "rm: remove directory '$from2'?"
		else
			echo -n "rm: remove regular file '$from2'?"
		fi
		read answer
		if [ "$answer" = 'y' -o "$answer" = 'Y' ];then
			echo "$dirname:$filename:$random:$(date +%Y-%m-%d.%T)" >> $mvlog
			mv "$from2" "$trash/$filename:$random"
		fi
	else
		if [ ! -e $from2 ];then
			file_null $from2
		fi
	fi
}

#清空回收站
function rmc()
{
	/bin/rm -rf $trash
}

function rml()
{
	local tmp=$(mktemp /tmp/tfile.XXXXXX)
	clear
	if [ ! -d "$trash" ];then
		mkdir $trash
	fi
	if [ ! -f "$mvlog" ];then
		touch $mvlog
	fi
	line=$(cat -n $mvlog | awk -F: '{print $1, "FileName:"$2, "Time: "$4":"$5":"$6}')
	linecount=$(cat $mvlog | wc -l)
	echo "$line"
	echo
	echo
	echo "[$linecount] Please enter the file you want to restore (replaced with the line number)"
	printf "RowNumber: "
	read answer
	if [ "$answer" = 'q' -o "$answer" = 'Q' -o "$answer" = "" ];then
		:
	else
		printf "Please confirm (Y/N): "
		read answer1
		if [ "$answer1" = 'y' -o "$answer1" = 'Y' ];then
			address=$(sed -n "$answer""p" $mvlog | awk -F: '{print $1}')
			filename=$(sed -n "$answer""p" $mvlog | awk -F: '{print $2}')
			filerand=$(sed -n "$answer""p" $mvlog | awk -F: '{print $3}')
			fullname=$address/$filename
			if [ -e "$fullname" ];then
				echo "The file exist!"
				sleep 0.5
			else
				old="$trash/$filename:$filerand"
				new="$address/$filename"
				mv "$old" "$new"
				#deline=$(cat $mvlog|sed "$answer""d" | sort -o $mvlog)
				deline=$(cat $mvlog|sed "$answer""d" >> $tmp)
				mv $tmp $mvlog
				echo "restore success!"
				sleep 0.5
			fi
		fi
	fi
}

function help()
{
 cat << 'EOF'
Usage: rm [OPTION]... FILE...
Remove (unlink) the FILE(s).
-f, --force   ignore nonexistent files, never prompt
-i, --interactive prompt before any removal
--no-preserve-root do not treat `/' specially (the default)
--preserve-root   fail to operate recursively on `/'
-r, -R, --recursive   remove directories and their contents recursively
--help display this help and exit
By default, rm does not remove directories.  Use the --recursive (-r or -R)
option to remove each listed directory, too, along with all of its contents.
To remove a file whose name starts with a `-', for example `-foo',
use one of these commands:
rm -- -foo
rm ./-foo
Note that if you use rm to remove a file, it is usually possible to recover
the contents of that file.  If you want more assurance that the contents are
truly unrecoverable, consider using shred.
EOF
}

#脚本开始
#检测回收站已用存储空间，如果已经达到最大值，则删除日志文件中位于前面的一半的文件
mem=$(du -s $trash|awk '{print $1}')
if [ "$mem" -gt $maxmemory ];then
	deal
fi

if [ "$#" -eq 0 ];then
	echo_msg
fi
if [ "$#" -eq 1 ];then
	case "$from1" in
		-i) 
			echo_msg
			;;
		-f) 
			echo_msg
			;;
		-r | -R)
			echo_msg
			;;
		-ir|-ri|-iR|-Ri|-if|-fi|-rf|-fr|-Rf|-fR)
			echo_msg
			;;
		-l)
			rml
			;;
		-c)
			rmc
			;;
		--help)
			help
			;;
		-*)
			echo_msg2 $from1
			;;
		*) 
			rm1
			;;
	esac
fi

if [ "$#" -ge 2 ];then
	until  [ "$2" = "" ]
	do
		from2=$2
		case "$from1" in
			-i)
				rmi
				;;
			-f)
				rmf
				;;
			-r|-R)
				rmr
				;;
			-l)
				rml
				;;
			-rf|-Rf|-fr|-fR)
				rmrf
				;;
			-ir|-ri|-iR|-Ri)
				rmir
				;;
			-if|-fi)
				rmf
				;;
			--help)
				help
				exit 1
				;;
			-*)
				echo_msg2 $from1
				exit 1
				;;
			*)
				{
				until [ "$1" = "" ]
				do
					from1=$1
					rm1
					shift
				done
				}
				;;
		esac
		shift
	done
fi
exit
