import ballerina/io as _;
import ballerina/time;
import ballerina/http;

type User record {|
    string userId;
    string name;
    int age;
    time:Date birthDate;
|};

type NewUser record {|
    string name;
    int age;
    time:Date birthDate;
|};

type ErrorMsg record {|
    string msg;
    string details;
    string code;
|};

type UserNotFound record {|
    *http:NotFound;
    ErrorMsg body;
|};

