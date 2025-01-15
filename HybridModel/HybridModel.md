# Hybrid Extensible Model for Semi-structured Data in SQLite

Datasets, such as bibliographic information libraries, present challenges to managing the data effectively in relational databases, because different reference types, such as *book* or *journal article*, have different sets of fields. Further, to cover a broad spectrum of use cases, a sufficiently large set of reference types needs to be used. Further yet, it is desirable to have the ability to define new types dynamically making it possible to tailor the data model to unusual scenarios. There are several approaches used to store such data in RDBMSs:
1. Flat Table Model
    Description:
    - All bibliographic information is stored in a single table.
    - Each row represents one reference (e.g., book, article, or patent).
    Advantages:
    - Simple and easy to implement.
    - Suitable for small datasets with limited variability in fields.
    Disadvantages:
    - Inefficient for highly diverse or large datasets due to sparse or unused columns.
    - Difficult to enforce data integrity for specific document types.
2. Normalized Relational Model
    Description:
    - Relational tables separate bibliographic information into core entities (e.g., authors, journals, publishers).
    - Individual reference types are stored in dedicated tables (e.g., books, patents, standards).
    Advantages:
    - High data integrity through normalization.
    - Efficiently supports complex queries (e.g., retrieving all articles by an author).
    Disadvantages:
    - Requires a more complex schema.
    - Joins are necessary for queries, which may impact performance for large datasets.
    - Ill-suited for common queries involving arbitrary sets of reference types.
3. Entity-Attribute-Value (EAV) or Vertical Model
    Description:
    - A flexible design where references and their attributes are stored separately.
    - Supports dynamic schema evolution without requiring database structure changes.
    Advantages:
    - Flexible and extensible, accommodating arbitrary attributes.
    - Ideal for datasets with highly variable or unpredictable metadata.
    Disadvantages:
    - Querying and reporting are more complex.
    - Harder to enforce constraints on attribute values.
4. Document-Oriented Model
    Description:
    - Uses JSON columns to store variable or nested bibliographic data while maintaining relational structure for core fields.
    Advantages:
    - Combines relational integrity with the flexibility of semi-structured data.
    - Suitable for datasets where metadata varies significantly by document type.
    Disadvantages:
    - JSON query capabilities depend on the features of the RDBMS in use.
    - Higher complexity when handling JSON fields programmatically.
    - Challenges with ensuring data integrity and efficient access at the database level.


