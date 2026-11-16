Feature: CAMARA Effective Capabilities and Restrictions API, vwip - Operation retrieveEffectiveOverlay

  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address.
  #   For this version, CAMARA does not allow the use of networkAccessIdentifier, so it is considered by default as not supported.
  # * Whether notification delivery (asynchronous mode with "sink") is supported. If not supported, the scenarios tagged
  #   with "@notifications" are expected to be skipped and the request with "sink" is expected to return 422 EVENT_NOTIFICATIONS_NOT_SUPPORTED.
  # * Whether sinkCredential of type ACCESSTOKEN is supported.
  # * Whether sinkCredential of type PRIVATE_KEY_JWT is supported. If not supported, the scenario for
  #   PRIVATE_KEY_JWT_NOT_CONFIGURED is expected to be skipped.
  # * The maximum time (notificationWaitTime) the tester has to wait for the notifications of a request to be received at the sink.
  # * The URLs of the released CAMARA API specifications supported by the implementation.
  # * Whether the environment can be configured to reject requests when the rate-limit threshold is reached (needed for the 429 scenario).
  #
  # Testing assets:
  # * A list of one or more URLs identifying released CAMARA API specifications supported by the implementation (supportedApiUrl, supportedApiUrl2).
  # * A URL identifying a released CAMARA API specification which is NOT supported by the implementation (unsupportedApiUrl).
  # * A device object known by the implementation (knownDevice), for which runtime restrictions can be evaluated.
  # * A device object compliant with the schema but which does not identify a device known by the implementation (unknownDevice).
  # * A device object identifying a device commercialized by the implementation for which the service is not applicable (notApplicableDevice), if any.
  # * An HTTPS sink endpoint controlled by the tester, able to receive and record CloudEvents (testSink), and the access token to be used as sinkCredential (testSinkAccessToken).
  # * An expired access token, an invalid access token, and an access token that does not include the scope
  #   "effective-capabilities-and-restrictions:retrieve-effective-overlay".
  #
  # Note: UNNECESSARY_IDENTIFIER and MISSING_IDENTIFIER are not tested: this API never derives the device from the access token,
  # and "device" is optional (see the API description), so these errors are not documented in the API specification.
  #
  # References to OAS spec schemas refer to schemas specified in effective-capabilities-and-restrictions.yaml

  Background: Common retrieveEffectiveOverlay setup
    Given an environment at "apiRoot"
    And the resource "/effective-capabilities-and-restrictions/vwip/retrieve-effective-overlay"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    # Properties not explicitly overwritten in the Scenarios can take any values compliant with the schema
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/RetrieveEffectiveOverlayRequest"

  # ---------------------------------------------------------------------------
  # Synchronous mode (no sink): 200 OK with an array of RestrictiveOverlay
  # ---------------------------------------------------------------------------

  @effective_capabilities_and_restrictions_01_sync_single_api_without_device
  Scenario: Retrieve the static overlay for one supported API without device
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is not included
    And the request body property "$.sink" is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/paths/~1retrieve-effective-overlay/post/responses/200/content/application~1json/schema"
    And the response property "$" is an array with exactly 1 item
    And the response property "$[0].overlay" is "1.1.0"
    And the response property "$[0].extends" is the same URL as the one provided in the request body property "$.apis[0]"

  @effective_capabilities_and_restrictions_02_sync_single_api_with_device
  Scenario: Retrieve the effective overlay for one supported API for a known device
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is set to "knownDevice"
    And the request body property "$.sink" is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/paths/~1retrieve-effective-overlay/post/responses/200/content/application~1json/schema"
    And the response property "$" is an array with exactly 1 item
    And the response property "$[0].overlay" is "1.1.0"
    And the response property "$[0].extends" is the same URL as the one provided in the request body property "$.apis[0]"

  @effective_capabilities_and_restrictions_03_sync_multiple_apis_same_order
  Scenario: Retrieve one overlay per requested API in the same order as the request
    Given the request body property "$.apis" is set as ["supportedApiUrl", "supportedApiUrl2"]
    And the request body property "$.sink" is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "/paths/~1retrieve-effective-overlay/post/responses/200/content/application~1json/schema"
    And the response property "$" is an array with exactly 2 items
    And the response property "$[0].extends" is the same URL as the one provided in the request body property "$.apis[0]"
    And the response property "$[1].extends" is the same URL as the one provided in the request body property "$.apis[1]"

  @effective_capabilities_and_restrictions_04_sync_device_by_each_supported_identifier
  Scenario Outline: Retrieve the effective overlay with a device identified by a supported identifier type
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device.<device_identifier>" is set to a valid value for a device known by the implementation
    And the device identifier type "<device_identifier>" is supported by the implementation
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "/paths/~1retrieve-effective-overlay/post/responses/200/content/application~1json/schema"
    And the response property "$[0].overlay" is "1.1.0"

    Examples:
      | device_identifier |
      | phoneNumber       |
      | ipv4Address       |
      | ipv6Address       |

  @effective_capabilities_and_restrictions_05_sync_repeated_request_same_overlay
  Scenario: Repeating a synchronous request returns the same overlay for a stable configuration
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is set to "knownDevice"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "/paths/~1retrieve-effective-overlay/post/responses/200/content/application~1json/schema"
    When the request "retrieveEffectiveOverlay" is sent again with the same request body
    Then the response status code is 200
    And the response body is equal to the response body of the previous request

  # ---------------------------------------------------------------------------
  # Asynchronous mode (implicit subscription): 202 Accepted and overlay-updated CloudEvents
  # ---------------------------------------------------------------------------

  @notifications
  @effective_capabilities_and_restrictions_06_notifications_async_with_sink
  Scenario: Request asynchronous delivery with sink and sinkCredential
    Given notification delivery is supported by the implementation
    And the sinkCredential type "ACCESSTOKEN" is supported by the implementation
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is set to "knownDevice"
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential.credentialType" is set as "ACCESSTOKEN"
    And the request body property "$.sinkCredential.accessToken" is set to "testSinkAccessToken"
    And the request body property "$.sinkCredential.accessTokenExpiresUtc" is set to a future date-time
    And the request body property "$.sinkCredential.accessTokenType" is set as "bearer"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/RetrieveEffectiveOverlayAccepted"
    And the response property "$.sink" has same value as the request body property "$.sink"
    And the response property "$.sinkCredential" does not exist

  @notifications
  @effective_capabilities_and_restrictions_07_notifications_async_without_credential
  Scenario: Request asynchronous delivery with sink and without sinkCredential
    Given notification delivery is supported by the implementation
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential" is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 202
    And the response body complies with the OAS schema at "#/components/schemas/RetrieveEffectiveOverlayAccepted"
    And the response property "$.sink" has same value as the request body property "$.sink"

  @notifications
  @effective_capabilities_and_restrictions_08_notifications_initial_overlay_updated_event
  Scenario: The initial overlay is delivered to the sink as one overlay-updated CloudEvent per requested API
    Given notification delivery is supported by the implementation
    And the sinkCredential type "ACCESSTOKEN" is supported by the implementation
    And the request body property "$.apis" is set as ["supportedApiUrl", "supportedApiUrl2"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential.credentialType" is set as "ACCESSTOKEN"
    And the request body property "$.sinkCredential.accessToken" is set to "testSinkAccessToken"
    And the request body property "$.sinkCredential.accessTokenExpiresUtc" is set to a future date-time
    And the request body property "$.sinkCredential.accessTokenType" is set as "bearer"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 202
    And the sink "testSink" receives 2 notifications within "notificationWaitTime", one per requested API
    And each notification "Content-Type" is "application/cloudevents+json"
    And each notification header "Authorization" is "Bearer" followed by the access token provided in "$.sinkCredential.accessToken"
    And each notification body complies with the OAS schema at "#/components/schemas/OverlayUpdatedEvent"
    And each notification property "$.id" is unique
    And each notification property "$.type" is "org.camaraproject.effective-capabilities-and-restrictions.v0.overlay-updated"
    And the notification properties "$.data.api" are the URLs provided in the request body property "$.apis", one in each notification
    And each notification property "$.data.overlay.extends" has same value as the notification property "$.data.api"
    And each notification property "$.data.overlay.overlay" is "1.1.0"

  # ---------------------------------------------------------------------------
  # Mandatory aspects of the specification (request body strictness and API-specific error)
  # ---------------------------------------------------------------------------

  # Examples: one top-level path, plus one path inside the object-typed property "device" of the request schema.
  # The object-typed property "sinkCredential" is covered by its own scenario because it needs "sink".
  @effective_capabilities_and_restrictions_09_request_body_unknown_property
  Scenario Outline: Request body with a property not declared in the specification is rejected
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is set to "knownDevice"
    And the request body includes the property "<undeclared_property>" which is not declared in the schema at "#/components/schemas/RetrieveEffectiveOverlayRequest"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema for this operation and status code

    Examples:
      | undeclared_property         |
      | $.undeclaredProperty        |
      | $.device.undeclaredProperty |

  @effective_capabilities_and_restrictions_10_api_not_supported
  Scenario: Request containing a CAMARA API specification not supported by the provider is rejected as a whole
    Given the request body property "$.apis" is set as ["unsupportedApiUrl"]
    And the request body property "$.sink" is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "EFFECTIVE_CAPABILITIES_AND_RESTRICTIONS.API_NOT_SUPPORTED"
    And the response property "$.message" exists
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema for this operation and status code

  # ---------------------------------------------------------------------------
  # Errors 400
  # ---------------------------------------------------------------------------

  @effective_capabilities_and_restrictions_11_400_schema_not_compliant
  Scenario: Invalid Argument. Generic Syntax Exception
    Given the request body is set to any value which is not compliant with the schema at "#/components/schemas/RetrieveEffectiveOverlayRequest"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_12_400_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_13_400_empty_request_body
  Scenario: Empty object as request body
    Given the request body is set to {}
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_14_400_missing_apis
  Scenario: Mandatory property apis is missing
    Given the request body property "$.apis" is not included
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_15_400_empty_apis_list
  Scenario: Empty list of APIs
    Given the request body property "$.apis" is set as []
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_16_400_duplicate_apis
  Scenario: Duplicate values in the list of APIs
    Given the request body property "$.apis" is set as ["supportedApiUrl", "supportedApiUrl"]
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_17_400_apis_item_not_a_uri
  Scenario: An item of the list of APIs is not a valid URI
    Given the request body property "$.apis[0]" is set to a value which does not comply with the format "uri"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_18_400_empty_property
  Scenario Outline: Error response for empty object property in request body
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "<object_property>" is set to {}
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

    Examples:
      | object_property  |
      | $.device         |
      | $.sinkCredential |

  @effective_capabilities_and_restrictions_19_400_unknown_property_in_sink_credential
  Scenario: Request body with a property not declared in sinkCredential is rejected
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential.credentialType" is set as "ACCESSTOKEN"
    And the request body property "$.sinkCredential.accessToken" is set to "testSinkAccessToken"
    And the request body property "$.sinkCredential.accessTokenExpiresUtc" is set to a future date-time
    And the request body property "$.sinkCredential.accessTokenType" is set as "bearer"
    And the request body includes the property "$.sinkCredential.undeclaredProperty" which is not declared in the schema at "#/components/schemas/RetrieveEffectiveOverlayRequest"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_20_400_sink_credential_without_sink
  Scenario: sinkCredential provided without sink is rejected
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is not included
    And the request body property "$.sinkCredential.credentialType" is set as "ACCESSTOKEN"
    And the request body property "$.sinkCredential.accessToken" is set to "testSinkAccessToken"
    And the request body property "$.sinkCredential.accessTokenExpiresUtc" is set to a future date-time
    And the request body property "$.sinkCredential.accessTokenType" is set as "bearer"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  # The pattern of sink (HTTPS only) is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT
  # without further distinction, and both could be accepted
  @effective_capabilities_and_restrictions_21_400_sink_not_https
  Scenario: Sink is not an HTTPS URL
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to a URL with the scheme "http"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_SINK" or "INVALID_ARGUMENT"
    And the response property "$.message" exists

  # PLAIN and REFRESHTOKEN are no longer valid "credentialType" values in the common SinkCredential schema,
  # so a request carrying them fails schema validation with INVALID_ARGUMENT.
  @effective_capabilities_and_restrictions_22_400_unsupported_sink_credential_type
  Scenario Outline: Unsupported sinkCredential.credentialType value
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential.credentialType" is set as "<unsupported_credential_type>"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

    Examples:
      | unsupported_credential_type |
      | PLAIN                       |
      | REFRESHTOKEN                |

  # Only "bearer" is considered in the schema so a generic schema validator may fail and generate a 400 INVALID_ARGUMENT without further distinction,
  # and both could be accepted
  @effective_capabilities_and_restrictions_23_400_sink_credential_invalid_token
  Scenario: Invalid token type in sinkCredential
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential.credentialType" is set as "ACCESSTOKEN"
    And the request body property "$.sinkCredential.accessToken" is set to "testSinkAccessToken"
    And the request body property "$.sinkCredential.accessTokenExpiresUtc" is set to a future date-time
    And the request body property "$.sinkCredential.accessTokenType" is set to a value other than "bearer"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_TOKEN" or "INVALID_ARGUMENT"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_24_400_invalid_x_correlator
  Scenario: Invalid x-correlator header
    Given the header "x-correlator" does not comply with the schema at "#/components/schemas/XCorrelator"
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

  # ---------------------------------------------------------------------------
  # Common error scenarios for management of input parameter device (Design Guide, Error Responses - Device Object)
  # ---------------------------------------------------------------------------

  @effective_capabilities_and_restrictions_25_400_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 400
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" exists

    Examples:
      | device_identifier                | oas_spec_schema                              |
      | $.device.phoneNumber             | #/components/schemas/PhoneNumber             |
      | $.device.ipv4Address             | #/components/schemas/DeviceIpv4Address       |
      | $.device.ipv6Address             | #/components/schemas/DeviceIpv6Address       |
      | $.device.networkAccessIdentifier | #/components/schemas/NetworkAccessIdentifier |

  # ---------------------------------------------------------------------------
  # Errors 401 and 403
  # ---------------------------------------------------------------------------

  @effective_capabilities_and_restrictions_26_401_no_authorization_header
  Scenario: Error response for no header "Authorization"
    Given the header "Authorization" is not sent
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" exists

  # In this case both codes could make sense depending on whether the access token can be refreshed or not
  @effective_capabilities_and_restrictions_27_401_expired_access_token
  Scenario: Error response for expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_28_401_invalid_access_token
  Scenario: Error response for invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 401
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_29_403_missing_access_token_scope
  Scenario: Missing access token scope
    Given the header "Authorization" is set to an access token that does not include scope "effective-capabilities-and-restrictions:retrieve-effective-overlay"
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 403
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" exists

  # ---------------------------------------------------------------------------
  # Errors 404
  # ---------------------------------------------------------------------------

  @effective_capabilities_and_restrictions_30_404_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is set to "unknownDevice", compliant with the schema but not identifying a valid device
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 404
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" exists

  # ---------------------------------------------------------------------------
  # Errors 422
  # ---------------------------------------------------------------------------

  @effective_capabilities_and_restrictions_31_422_unsupported_device_identifier
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" exists

  # When the service is only offered to certain types of devices or subscriptions, e.g. IoT, B2C, etc.
  @effective_capabilities_and_restrictions_32_422_service_not_applicable
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.device" is set to "notApplicableDevice"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" exists

  @effective_capabilities_and_restrictions_33_422_event_notifications_not_supported
  Scenario: Request with sink is rejected when notification delivery is not supported
    Given notification delivery is not supported by the implementation
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "EVENT_NOTIFICATIONS_NOT_SUPPORTED"
    And the response property "$.message" exists
    And the sink "testSink" receives no notification

  @effective_capabilities_and_restrictions_34_422_private_key_jwt_not_configured
  Scenario: PRIVATE_KEY_JWT sink credential used but not pre-configured
    Given notification delivery is supported by the implementation
    And the sinkCredential type "PRIVATE_KEY_JWT" is supported by the implementation
    And the request body property "$.apis" is set as ["supportedApiUrl"]
    And the request body property "$.sink" is set to the HTTPS URL of the tester-controlled sink "testSink"
    And the request body property "$.sinkCredential.credentialType" is set as "PRIVATE_KEY_JWT"
    And no PRIVATE_KEY_JWT configuration has been pre-shared for the notification endpoint
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 422
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 422
    And the response property "$.code" is "PRIVATE_KEY_JWT_NOT_CONFIGURED"
    And the response property "$.message" exists

  # ---------------------------------------------------------------------------
  # Errors 429
  # ---------------------------------------------------------------------------

  # To test this scenario the environment has to be configured to reject requests reaching the threshold limit set.
  @effective_capabilities_and_restrictions_35_429_too_many_requests
  Scenario: Request is rejected due to threshold policy
    Given the request body property "$.apis" is set as ["supportedApiUrl"]
    And the threshold of requests has been reached
    When the request "retrieveEffectiveOverlay" is sent
    Then the response status code is 429
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 429
    And the response property "$.code" is "TOO_MANY_REQUESTS" or "QUOTA_EXCEEDED"
    And the response property "$.message" exists
