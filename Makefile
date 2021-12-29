SHELL    = /bin/bash

PG_HOST ?= localhost
DB_NAME ?= tender
DB_USER ?= tender
DB_PASS ?= 1234tender

all:
	
	PGPASSWORD=$(DB_PASS) psql -h $(PG_HOST) -U $(DB_USER) $(DB_NAME) -f make.sql

clean: 
	rm -f *.res rm make.tmp.sql
