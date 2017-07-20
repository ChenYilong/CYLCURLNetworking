//
//  lchttp.h
//  ALFNetworking
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#include "curl.h"

struct lchttp_error_t {
    CURLcode code;
    char *message;
};

struct lchttp_response_t {
    long code;
    char *header;
    char *text;
};

typedef struct lchttp_error_t lchttp_error_t;
typedef struct lchttp_response_t lchttp_response_t;

lchttp_error_t *lchttp_error_init();
lchttp_response_t *lchttp_response_init();

CURLcode lchttp_perform(CURL *curl, lchttp_response_t *response, lchttp_error_t *error);

void lchttp_response_destroy(lchttp_response_t *response);
void lchttp_error_destroy(lchttp_error_t *error);
