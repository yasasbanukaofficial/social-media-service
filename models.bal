import ballerina/http;
import ballerina/sql;
import ballerina/time;
import ballerina/constraint;

public type User record {|
    @sql:Column {
        name: "id"
    }
    readonly int userId;

    @constraint:String{
        maxLength: 5,
        minLength: 1
    }
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

public type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

public type ErrorMsg record {|
    string msg;
    string details;
    time:Utc timeStamp;
|};

public type UserNotFound record {|
    *http:NotFound;
    ErrorMsg body;
|};

public type DBConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

// post representations
public type Post record {|
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

public type PostForbidden record {|
    *http:Forbidden;
    ErrorDetails body;
|};

public type ErrorDetails record {|
    time:Utc timeStamp;
    string message;
    string details;
|};

public type Created_date record {|
    int year;
    int month;
    int day;
    json...;
|};

public type Meta record {|
    string[] tags;
    string category;
    Created_date created_date;
    json...;
|};

public type PostWithMeta record {|
    int id;
    string description;
    Meta meta;
    json...;
|};

