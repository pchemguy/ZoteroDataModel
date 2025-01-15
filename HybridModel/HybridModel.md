# Hybrid Pseudo-Relational Extensible Model for Semi-structured Data in SQLite

Datasets, such as libraries of references present challenges to managing the data effectively in relational databases, because different reference types, such as *book* or *journal article*, have different sets of fields. Further, to cover a broad spectrum of use cases, a sufficiently large set of reference types needs to be used. Further yet, it is desirable to have the ability to define new types dynamically making it possible to tailor the data model to unusual scenarios.

There are several approaches used to store such data in RDBMSs.
1. The normalized design with one database table for each distinct reference type.
  