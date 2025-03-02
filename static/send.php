<definitions xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:tns="urn:Send" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns="http://schemas.xmlsoap.org/wsdl/" targetNamespace="urn:Send">
<types>
<xsd:schema targetNamespace="urn:Send">
<xsd:import namespace="http://schemas.xmlsoap.org/soap/encoding/"/>
<xsd:import namespace="http://schemas.xmlsoap.org/wsdl/"/>
<xsd:complexType name="ListArray">
<xsd:complexContent>
<xsd:restriction base="SOAP-ENC:Array">
<xsd:attribute ref="SOAP-ENC:arrayType" wsdl:arrayType="xsd:string"/>
</xsd:restriction>
</xsd:complexContent>
</xsd:complexType>
<xsd:complexType name="InputDate">
<xsd:all>
<xsd:element name="year" type="xsd:string"/>
<xsd:element name="month" type="xsd:string"/>
<xsd:element name="day" type="xsd:string"/>
<xsd:element name="hour" type="xsd:string"/>
<xsd:element name="min" type="xsd:string"/>
</xsd:all>
</xsd:complexType>
</xsd:schema>
</types>
<message name="registeruserRequest">
<part name="register_personality" type="xsd:string"/>
<part name="company" type="xsd:string"/>
<part name="company_reg_number" type="xsd:string"/>
<part name="company_eco_code" type="xsd:string"/>
<part name="company_melli_id" type="xsd:string"/>
<part name="company_type" type="xsd:string"/>
<part name="first_name" type="xsd:string"/>
<part name="last_name" type="xsd:string"/>
<part name="father" type="xsd:string"/>
<part name="gender" type="xsd:string"/>
<part name="uname" type="xsd:string"/>
<part name="upass" type="xsd:string"/>
<part name="upass_repeat" type="xsd:string"/>
<part name="date" type="xsd:string"/>
<part name="shenasname" type="xsd:string"/>
<part name="melli_code" type="xsd:string"/>
<part name="email" type="xsd:string"/>
<part name="mob" type="xsd:string"/>
<part name="tel" type="xsd:string"/>
<part name="fax" type="xsd:string"/>
<part name="post_code" type="xsd:string"/>
<part name="addr" type="xsd:string"/>
<part name="referrer" type="xsd:string"/>
<part name="package" type="xsd:string"/>
<part name="reseller" type="xsd:string"/>
</message>
<message name="registeruserResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="SendMultiSMSRequest">
<part name="fromNum" type="xsd:string"/>
<part name="toNum" type="xsd:string"/>
<part name="Content" type="tns:ListArray"/>
<part name="Type" type="tns:ListArray"/>
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
</message>
<message name="SendMultiSMSResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="FutureSendMultiSMSRequest">
<part name="uname" type="xsd:string"/>
<part name="pass" type="xsd:string"/>
<part name="from" type="xsd:string"/>
<part name="to" type="tns:ListArray"/>
<part name="msg" type="xsd:string"/>
<part name="sentdate" type="tns:InputDate"/>
<part name="prtrys" type="xsd:string"/>
<part name="sentperiod" type="xsd:string"/>
</message>
<message name="FutureSendMultiSMSResponse">
<part name="return" type="xsd:string[]"/>
</message>
<message name="SendSMSRequest">
<part name="fromNum" type="xsd:string"/>
<part name="toNum" type="xsd:string"/>
<part name="Content" type="xsd:string"/>
<part name="Type" type="xsd:string"/>
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
</message>
<message name="SendSMSResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="SendOfPhoneBookRequest">
<part name="fromNum" type="xsd:string"/>
<part name="phonebook" type="xsd:int"/>
<part name="Content" type="xsd:string"/>
<part name="Type" type="xsd:string"/>
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
</message>
<message name="SendOfPhoneBookResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="AddToPhonebookRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="Phonebook" type="xsd:string"/>
<part name="Numbers" type="tns:ListArray"/>
</message>
<message name="AddToPhonebookResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="AddPhonebookRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="Name" type="xsd:string"/>
<part name="Numbers" type="tns:ListArray"/>
</message>
<message name="AddPhonebookResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="listPhonebookRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="Name" type="xsd:string"/>
</message>
<message name="listPhonebookResponse">
<part name="return" type="xsd:string[]"/>
</message>
<message name="numbersPhonebookRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="BookID" type="xsd:string"/>
</message>
<message name="numbersPhonebookResponse">
<part name="return" type="xsd:string[]"/>
</message>
<message name="deleteNumbersOfPhonebookRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="BookID" type="xsd:string"/>
<part name="Numbers" type="tns:ListArray"/>
</message>
<message name="deleteNumbersOfPhonebookResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="deletePhonebookRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="BookID" type="xsd:string"/>
</message>
<message name="deletePhonebookResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="GetCreditRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
</message>
<message name="GetCreditResponse">
<part name="return" type="xsd:string"/>
</message>
<message name="detailsRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
</message>
<message name="detailsResponse">
<part name="return" type="xsd:string"/>
</message>
<message name="getpermRequest">
<part name="Username" type="xsd:string"/>
</message>
<message name="getpermResponse">
<part name="return" type="xsd:string"/>
</message>
<message name="GetLastSendRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
</message>
<message name="GetLastSendResponse">
<part name="return" type="tns:ListArray"/>
</message>
<message name="GetStatusRequest">
<part name="Username" type="xsd:string"/>
<part name="Password" type="xsd:string"/>
<part name="Unique_ids" type="tns:ListArray"/>
</message>
<message name="GetStatusResponse">
<part name="return" type="tns:ListArray"/>
</message>
<portType name="SendPortType">
<operation name="registeruser">
<documentation>Register New User</documentation>
<input message="tns:registeruserRequest"/>
<output message="tns:registeruserResponse"/>
</operation>
<operation name="SendMultiSMS">
<documentation>Send Multiple Content To Multiple Numbers</documentation>
<input message="tns:SendMultiSMSRequest"/>
<output message="tns:SendMultiSMSResponse"/>
</operation>
<operation name="FutureSendMultiSMS">
<documentation>Send Multiple Content To Multiple Numbers</documentation>
<input message="tns:FutureSendMultiSMSRequest"/>
<output message="tns:FutureSendMultiSMSResponse"/>
</operation>
<operation name="SendSMS">
<documentation>Send Message To Array List Of Numbers</documentation>
<input message="tns:SendSMSRequest"/>
<output message="tns:SendSMSResponse"/>
</operation>
<operation name="SendOfPhoneBook">
<documentation>Send Message To Array List Of Numbers</documentation>
<input message="tns:SendOfPhoneBookRequest"/>
<output message="tns:SendOfPhoneBookResponse"/>
</operation>
<operation name="AddToPhonebook">
<documentation>Add Numbers To Phonebook</documentation>
<input message="tns:AddToPhonebookRequest"/>
<output message="tns:AddToPhonebookResponse"/>
</operation>
<operation name="AddPhonebook">
<documentation>Add Numbers To Phonebook</documentation>
<input message="tns:AddPhonebookRequest"/>
<output message="tns:AddPhonebookResponse"/>
</operation>
<operation name="listPhonebook">
<documentation>Add Numbers To Phonebook</documentation>
<input message="tns:listPhonebookRequest"/>
<output message="tns:listPhonebookResponse"/>
</operation>
<operation name="numbersPhonebook">
<documentation>Add Numbers To Phonebook</documentation>
<input message="tns:numbersPhonebookRequest"/>
<output message="tns:numbersPhonebookResponse"/>
</operation>
<operation name="deleteNumbersOfPhonebook">
<documentation>Add Numbers To Phonebook</documentation>
<input message="tns:deleteNumbersOfPhonebookRequest"/>
<output message="tns:deleteNumbersOfPhonebookResponse"/>
</operation>
<operation name="deletePhonebook">
<documentation>Add Numbers To Phonebook</documentation>
<input message="tns:deletePhonebookRequest"/>
<output message="tns:deletePhonebookResponse"/>
</operation>
<operation name="GetCredit">
<documentation>Check User Charge</documentation>
<input message="tns:GetCreditRequest"/>
<output message="tns:GetCreditResponse"/>
</operation>
<operation name="details">
<documentation>Check User exist</documentation>
<input message="tns:detailsRequest"/>
<output message="tns:detailsResponse"/>
</operation>
<operation name="getperm">
<documentation>Check User exist</documentation>
<input message="tns:getpermRequest"/>
<output message="tns:getpermResponse"/>
</operation>
<operation name="GetLastSend">
<documentation>Get last send report</documentation>
<input message="tns:GetLastSendRequest"/>
<output message="tns:GetLastSendResponse"/>
</operation>
<operation name="GetStatus">
<documentation>Get Message Delivery Status</documentation>
<input message="tns:GetStatusRequest"/>
<output message="tns:GetStatusResponse"/>
</operation>
</portType>
<binding name="SendBinding" type="tns:SendPortType">
<soap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
<operation name="registeruser">
<soap:operation soapAction="registeruser" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="SendMultiSMS">
<soap:operation soapAction="SendMultiSMS" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="FutureSendMultiSMS">
<soap:operation soapAction="SendMultiSMS" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="SendSMS">
<soap:operation soapAction="SendSMS" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="SendOfPhoneBook">
<soap:operation soapAction="SendOfPhoneBook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="AddToPhonebook">
<soap:operation soapAction="AddToPhonebook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="AddPhonebook">
<soap:operation soapAction="AddPhonebook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="listPhonebook">
<soap:operation soapAction="listPhonebook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="numbersPhonebook">
<soap:operation soapAction="numbersPhonebook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="deleteNumbersOfPhonebook">
<soap:operation soapAction="deleteNumbersOfPhonebook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="deletePhonebook">
<soap:operation soapAction="deletePhonebook" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="GetCredit">
<soap:operation soapAction="GetCredit" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="details">
<soap:operation soapAction="details" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="getperm">
<soap:operation soapAction="getperm" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="GetLastSend">
<soap:operation soapAction="GetLastSend" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
<operation name="GetStatus">
<soap:operation soapAction="GetStatus" style="rpc"/>
<input>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</input>
<output>
<soap:body use="encoded" namespace="Send_API" encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"/>
</output>
</operation>
</binding>
<service name="Send">
<port name="SendPort" binding="tns:SendBinding">
<soap:address location="http://87.248.137.75/webservice/send.php"/>
</port>
</service>
</definitions>