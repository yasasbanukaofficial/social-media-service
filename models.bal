import ballerina/http;
import ballerina/sql;
import ballerina/time;

type User record {|
    @sql:Column {
        name: "id"
    }
    readonly int userId;
    string name;
    int age;
    
    @sql:Column {
        name: "birth_date"
    }
    time:Date birthDate;
    
    @sql:Column {
        name: "mobile_number"
    }
    string mobileNumber;
|};

type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

type ErrorMsg record {|
    string msg;
    string details;
    time:Utc timeStamp;
|};

type UserNotFound record {|
    *http:NotFound;
    ErrorMsg body;
|};

type DBConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

// post representations
type Post record {|
    int id;
    string description;
    string tags;
    string category;
    @sql:Column {name: "created_date"}
    time:Date created_date;

    @sql:Column {name: "user_id"}
    string userId;
|};

public type NewPost record {|
    string description;
    string tags;
    string category;
|};

type PostForbidden record {|
    *http:Forbidden;
    ErrorDetails body;
|};

type ErrorDetails record {|
    time:Utc timeStamp;
    string message;
    string details;
|};

type Created_date record {|
    int year;
    int month;
    int day;
    json...;
|};

type Meta record {|
    string[] tags;
    string category;
    Created_date created_date;
    json...;
|};

type PostWithMeta record {|
    int id;
    string description;
    Meta meta;
    json...;
|};

