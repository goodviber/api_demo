# api_demo
Rails Api with rspec and serializers

### Create a Workspace [POST]

This allows anyone to create a new, closed and messaging-enabled workspace.

> **Note:** A streamlined, list/cache-friendly version of the workspace model is returned. An additional call will be required to retrieve the full workspace model. (e.g. When switching workspace?)

+ Attributes
    + workspace (object)
        + name (string, required) - This value will be used as the `name` **and** `nickname` for the workspace.
        + newsletter (boolean) - Indicates **user's** consent, or otherwise, to receive newsletter of messaging updates. _Assumed `false` if not provided. **Overwrites existing user's setting.**_
        + parent_id (number) - A L0 workspace to subscribe to the numbers of.
        + terms_of_use (boolean) - Indicates acceptance of the terms of use. _No longer required._

+ Request (application/json)

        {
            "workspace": {
                "name": "Workspace Name",
                "newsletter": false,
                "parent_id": 12
            }
        }

+ Response 201 (application/json)

            {
                "data": {
                    "id": 2,
                    "name": "Workspace Name",
                    "nickname": "Workspace Name",
                    "parent_id": 12,
                    "updated_at": "2019-09-13T08:00:00.000Z"
                },
                "meta": {}
            }

+ Response 422 (application/json)

            {
                "errors": [
                    {
                        "title": "Could not create workspace",
                        "code": "create_workspace_failed",
                        "meta": {
                            "name": [
                                { "error": "blank" }
                            ],
                            "parent": [
                                { "error": "closed" }
                            ]
                        }
                    }
                ],
                "meta": {}
            }

## Workspace [/workspaces/{id}]

### View a Workspace [GET]

This allows to get a workspace.

+ Parameters
    + id (number, required)- ID of the Workspace to update in the form of an integer

+ Response 200 (application/json)

            {
                "data": [
                    {
                        "id": 1,
                        "name": "workspace 1",
                        "nickname": "workspace nickname 1",
                        "parent_id": null,
                        "updated_at": "2019-10-23T08:17:12.157Z",
                        "messaging_enabled": false,
                        "closed_network_enabled": false,
                        "creator_id": 4,
                        "admin_users": [
                            {
                                "id": 22,
                                "first_name": "c7abe1ab-3e48-424b-8379-75528e676bb7",
                                "last_name": "ecb4608e-2054-4cd4-8677-40b4165bc8f9",
                                "role": "physiotherapist",
                                "has_enabled_messaging": false,
                                "job_title": null
                            }
                        ]
                    }
                ]
            }


+ Response 401 (application/json)

            {
                "errors": [
                    {
                        "title": "Unauthorized",
                        "code": "unauthorized",
                        "meta": {}
                    }
                ],
                "meta": {}
            }

+ Response 403 (application/json)

            {
                "errors": [
                    {
                        "title": "Please confirm your email address before making this request",
                        "code": "unconfirmed_user",
                        "meta": {}
                    }
                ],
                "meta": {
                    confirmation_required: true
                }
            }

### Update a Workspace [PATCH]

This allows anyone to update an existing, closed and messaging-enabled workspace.

> **Note:** A streamlined, list/cache-friendly version of the workspace model is returned. An additional call will be required to retrieve the full workspace model. (e.g. When switching workspace?)

+ Attributes
    + workspace (object)
        + name (string, required) - This value can be renamed as `name` and `nickname` by the admin of the workspace.

+ Request (application/json)

        {
            "workspaces/1": {
                "name": "Another Workspace Name",
                "nickname": "Another Workspace Nickname"
            }
        }

+ Response 201 (application/json)

            {
                "data": {
                    "id": 1,
                    "name": "Another Workspace Name",
                    "nickname": "Another Workspace Nickname",
                    "updated_at": "2019-09-13T08:00:00.000Z"
                },
                "meta": {}
            }

+ Response 422 (application/json)

            {
                "errors": [
                    {
                        "title": "Could not update workspace",
                        "code": "update_workspace_failed",
                        "meta": {
                            "name": [
                                { "error": "blank" }
                            ],
                        }
                    }
                ],
                "meta": {}
            }
