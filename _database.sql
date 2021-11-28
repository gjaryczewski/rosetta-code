CREATE DATABASE rosettacode
ON
( NAME = rosettacode_data,
    FILENAME = 'C:\DATA\rosettacode.mdf',
    SIZE = 10,
    MAXSIZE = 50,
    FILEGROWTH = 5 )
LOG ON
( NAME = rosettacode_log,
    FILENAME = 'C:\DATA\rosettacode.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB ) ;
GO