import ballerinax/mysql;
import ballerina/test;
import ballerina/http;

@test:Mock{
    functionName: "initSocialMediaDb"
}
function initMockSocialMediaDb() returns mysql:Client|error => test:mock(mysql:Client);

@test:Config{}
function testUsersById() returns error? {
    User userExpected = { userId: 999, name: "foo", age: 0, birthDate: {year: 0, month: 0, day: 0}, mobileNumber: "1234567890"};
    test:prepare(socialMediaDB).when("queryRow").thenReturn(userExpected);

    http:Client socialMediaEndpoint = check new("localhost:9090/social-media");
    User userActual = check socialMediaEndpoint->/users/[userExpected.userId.toString()];

    test:assertEquals(userActual, userExpected);
}