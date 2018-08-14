# Movie-Recommendation-System

This package consists of three folders: setup, databsets and Screenshots.

Setup contains two folders: hadoop-2.9.0 and hive-2.1.1,

Databsets contains: movies.dat and ratings.dat,

Screenshots contains some project screenshots.

## 1. Hadoop Installation:

Hadoop Prerequisites

### Java 8 JDK installation:

```
$ sudo add-apt-repository ppa:webupd8team/java
$ sudo apt-get update
$ sudo apt-get install oracle-java8-installer
```

Passwordless SSH authentication:

```
$ sudo apt-get install openssh-server
$ ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
$ ssh localhost
$ exit
```

Move the folder "hadoop-2.9.0" to /opt

```
$ sudo mv hadoop-2.9.0 /opt
```

this will be the hadoop installation directory

Goto the hadoop installation directory /opt/hadoop-2.9.0.

```
$ cd /opt/hadoop-2.9.0
```

this contains all the pre-configured files required by the hadoop.
(files are manually configured by the project team)

These files are located in /etc/hadoop folder in hadoop installation directory.

> hadoop-env.sh

> core-site.xml

> hdfs-site.xml

> mapred-site.xml

> yarn-site.xml

At this point, we are done with the configuration and are ready to get them started.

```
$ sbin/hdfs namenode -format

$ sbin/start-dfs.sh

$ sbin/start-yarn.sh

$ jps
```

jps will show the status of running components.

That's it for installation of Hadoop in Pseudo-distributed mode.


## 2. Hive Installation:

First we have to move hive-2.1.1 folder to the location /opt
This will be the installation directory for Hive.

```
$ sudo mv hive-2.1.1 /opt
```

Now we have to set environment variables,

```
$ nano ~/.bashrc
```

Add the following lines at the top of the contents of the file

```
###
export HADOOP_HOME='/opt/hadoop-2.9.0'
export PATH=$PATH:$HADOOP_HOME/bin

export HIVE_HOME='/opt/apache-hive-2.1.1'
export PATH=$PATH:$HIVE_HOME/bin

export CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:.
export CLASSPATH=$CLASSPATH:$HIVE_HOME/lib/*:.
###
```

And, reflect the changes

```
$ source ~/.bashrc
```

Goto the directory /conf and open up the file "hive-site.xml"

Replace all references to the system username with the username that you have on your machine
i.e. replace "${system:user.name}" with "your_username" and save the file.

Run some following commands to create directory for /temp and /warehouse for the Hive.

```
$ hadoop fs -mkdir /tmp
$ hadoop fs -mkdir /user
$ hadoop fs -mkdir /user/hive
$ hadoop fs -mkdir /user/hive/warehouse

$ hadoop fs -chmod g+w /tmp
$ hadoop fs -chmod g+w /user/hive/warehouse
```

By running hive cmd, you will notice some errors
So, let's run it.

```
$ hive
```

To remove error run some commands

```
$ mv metastore_db metastore_db.tmp
$ schematool -initSchema -dbType derby
```

Now, we are ready to run Hive

```
$ hive
```

That's it for Hive Installation.

## 3. Data preparation

You can find two dat file in the archive folder datasets:

> movies.dat, ratings.dat.

Change column separator as follows:

```
$ sed 's/::/#/g' movies.dat > movies.txt
$ sed 's/::/#/g' ratings.dat > ratings.txt
$ sed 's/::/#/g' users.dat > users.txt
```

## 4. Importing data as Hive tables

--> create tables

```
create database movie_db;
use movie_db;
```

--> Create TXT table
```
CREATE TABLE ratings_txt (
  userid INT, 
  movieid INT,
  rating DOUBLE, 
  tstamp STRING
) STORED AS TEXTFILE;


CREATE TABLE movies_txt (
  movieid INT, 
  title STRING,
  genres ARRAY<STRING>
) STORED AS TEXTFILE;;
```

--> Load into Text table
```
LOAD DATA LOCAL INPATH '/path/to/movies.txt' INTO TABLE ratings_txt;
LOAD DATA LOCAL INPATH '/path/to/movies.txt' INTO TABLE movies_txt;
```

--> Create ORC table
```
CREATE TABLE ratings_orc (
  userid INT, 
  movieid INT,
  rating DOUBLE, 
  tstamp STRING
) ROW FORMAT DELIMITED
FIELDS TERMINATED BY '#'
STORED AS ORC tblproperties("compress.mode"="SNAPPY");

CREATE TABLE movies_orc (
  movieid INT, 
  title STRING,
  genres ARRAY<STRING>
) ROW FORMAT DELIMITED
FIELDS TERMINATED BY '#'
COLLECTION ITEMS TERMINATED BY "|"
STORED AS ORC tblproperties("compress.mode"="SNAPPY");
```

--> Copy to ORC table
```
INSERT INTO TABLE ratings_orc SELECT * FROM ratings_txt;
INSERT INTO TABLE movies_orc SELECT * FROM movies_txt;
```

## 5. load data into tables

```
$ hadoop fs -put ratings.txt /dataset/movielens/ratings
$ hadoop fs -put movies.txt /dataset/movielens/movies
```

Finally save the following query in a file with a extention '.hql' on local path (say query.hql).

```
use movie_db;

SELECT t.movieid as movieid, t.counts as rating_count, t.average as avg_rating, SUBSTRING(movies_orc.title, 1, 30) as movie_name, movies_orc.genres as genre FROM
(SELECT movieid, count(rating) as counts, round(avg(rating), 2) as average FROM ratings_orc GROUP BY movieid SORT BY average DESC, counts DESC	) t JOIN movies_orc ON (t.movieid = movies_orc.movieid)
WHERE counts > 10 AND array_contains(movies_orc.genres, 'Sci-Fi')
limit 15;
```

Now exit hive using 'exit;' cmd

It's time to run the query for the top 15 movies of genre 'Sci-Fi':

```
$ cd $HIVE_HOME
$ bin/beeline -u jdbc:hive2:// -f /path/to/file/query.hql
```

