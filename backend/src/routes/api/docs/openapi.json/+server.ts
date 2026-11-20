
import { json } from '@sveltejs/kit';

export const GET = () => {
    const spec = {
        openapi: '3.0.0',
        info: {
            title: 'ATK Backend API',
            version: '1.0.0',
            description: 'API documentation for the ATK Survey Application'
        },
        servers: [
            {
                url: 'http://localhost:8000',
                description: 'Local Development Server'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                }
            }
        },
        security: [
            {
                bearerAuth: []
            }
        ],
        paths: {
            '/api/send-otp': {
                post: {
                    summary: 'Send OTP',
                    description: 'Sends a one-time password to the provided email address.',
                    security: [], 
                    requestBody: {
                        required: true,
                        content: {
                            'application/json': {
                                schema: {
                                    type: 'object',
                                    properties: {
                                        email: {
                                            type: 'string',
                                            format: 'email',
                                            example: 'user@example.com'
                                        }
                                    },
                                    required: ['email']
                                }
                            }
                        }
                    },
                    responses: {
                        '200': {
                            description: 'OTP sent successfully',
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            debug_otp: {
                                                type: 'string',
                                                description: 'For development only: The OTP code sent.'
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        '400': {
                            description: 'Bad Request'
                        }
                    }
                }
            },
            '/api/verify-otp': {
                post: {
                    summary: 'Verify OTP',
                    description: 'Verifies the OTP and returns a JWT token.',
                    security: [], 
                    requestBody: {
                        required: true,
                        content: {
                            'application/json': {
                                schema: {
                                    type: 'object',
                                    properties: {
                                        email: {
                                            type: 'string',
                                            format: 'email'
                                        },
                                        otp: {
                                            type: 'string'
                                        }
                                    },
                                    required: ['email', 'otp']
                                }
                            }
                        }
                    },
                    responses: {
                        '200': {
                            description: 'OTP valid, token returned',
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            token: {
                                                type: 'string'
                                            },
                                            user: {
                                                type: 'object',
                                                properties: {
                                                    email: { type: 'string' },
                                                    id: { type: 'integer' }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        '401': {
                            description: 'Invalid OTP'
                        }
                    }
                }
            },
            '/api/surveys/start': {
                post: {
                    summary: 'Start Survey',
                    description: 'Initializes a survey session for the authenticated user.',
                    responses: {
                        '200': {
                            description: 'Survey started',
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            data: {
                                                type: 'object',
                                                properties: {
                                                    id: { type: 'integer' },
                                                    answers: {
                                                        type: 'array',
                                                        items: {
                                                            type: 'object',
                                                            properties: {
                                                                question: {
                                                                    type: 'object',
                                                                    properties: { slug: { type: 'string' } }
                                                                },
                                                                value_text: { type: 'string', nullable: true },
                                                                value_number: { type: 'number', nullable: true }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        '401': { description: 'Unauthorized' }
                    }
                }
            },
            '/api/surveys/questions': {
                get: {
                    summary: 'Get Questions',
                    description: 'Fetches all survey questions and options.',
                    responses: {
                        '200': {
                            description: 'Questions fetched successfully',
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            success: { type: 'boolean' },
                                            questions: {
                                                type: 'array',
                                                items: {
                                                    type: 'object',
                                                    properties: {
                                                        id: { type: 'string', description: 'Question Slug' },
                                                        text: { type: 'string' },
                                                        type: { type: 'string' },
                                                        options: {
                                                            type: 'array',
                                                            items: {
                                                                type: 'object',
                                                                properties: {
                                                                    label: { type: 'string' },
                                                                    value: { type: 'string' }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        '401': { description: 'Unauthorized' }
                    }
                }
            },
            '/api/surveys/answer': {
                post: {
                    summary: 'Submit Answer',
                    description: 'Submits an answer to a specific question.',
                    requestBody: {
                        required: true,
                        content: {
                            'application/json': {
                                schema: {
                                    type: 'object',
                                    properties: {
                                        submission_id: { type: 'integer' },
                                        question_slug: { type: 'string' },
                                        value: {
                                            oneOf: [
                                                { type: 'string' },
                                                { type: 'number' },
                                                { type: 'boolean' },
                                                { type: 'array', items: { type: 'string' } }
                                            ]
                                        }
                                    },
                                    required: ['submission_id', 'question_slug', 'value']
                                }
                            }
                        }
                    },
                    responses: {
                        '200': {
                            description: 'Answer saved',
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            success: { type: 'boolean' }
                                        }
                                    }
                                }
                            }
                        },
                        '400': { description: 'Bad Request' },
                        '401': { description: 'Unauthorized' }
                    }
                }
            },
            '/api/reset-survey': {
                post: {
                    summary: 'Reset Survey Data',
                    description: 'Deletes all survey submissions and answers for the authenticated user (Development Utility).',
                    responses: {
                        '200': {
                            description: 'Reset successful',
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            success: { type: 'boolean' },
                                            message: { type: 'string' }
                                        }
                                    }
                                }
                            }
                        },
                        '401': { description: 'Unauthorized' },
                        '500': { description: 'Internal Server Error' }
                    }
                }
            }
        }
    };

    return json(spec);
};
