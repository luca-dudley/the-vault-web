# The Vault: Supabase Master Schema & Storage Policies

This file serves as the Single Source of Truth for database tables, column structures, Row Level Security (RLS) policies, and storage buckets.

---

## 1. Database Schema & RLS Policies
database_architecture_schema
"{
    ""tables"": {
        ""sops"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""description"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""category"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Agriculture'::text""
            },
            {
                ""column"": ""sub_tag"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'General Safety'::text""
            },
            {
                ""column"": ""doc_url"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""video_id"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""updated_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""company_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""curriculum_slug"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""partner_docs"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'{}'::jsonb""
            }
        ],
        ""videos"": [
            {
                ""column"": ""id"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""category"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Agriculture'::text""
            },
            {
                ""column"": ""language"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'English'::text""
            },
            {
                ""column"": ""total_seconds"",
                ""data_type"": ""int4"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""thumbnail_url"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""description"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""objectives"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""sub_tag"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""company_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""questions"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""curriculum_slug"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""partner_thumbnails"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": ""'{}'::jsonb""
            }
        ],
        ""profiles"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""first_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""last_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""role"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Staff'::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""timezone('utc'::text, now())""
            },
            {
                ""column"": ""avatar_url"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""tier"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'basic'::text""
            }
        ],
        ""companies"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""subscription_status"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'active'::text""
            },
            {
                ""column"": ""seat_limit"",
                ""data_type"": ""int4"",
                ""is_nullable"": true,
                ""default_value"": ""5""
            },
            {
                ""column"": ""tier"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Base'::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""timezone('utc'::text, now())""
            },
            {
                ""column"": ""paystack_subscription_code"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""paystack_customer_code"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""vat_number"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""postal_address"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""phone"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""contact_email"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""partner_grower_codes"",
                ""data_type"": ""_text"",
                ""is_nullable"": true,
                ""default_value"": ""'{}'::text[]""
            },
            {
                ""column"": ""sponsored_crop_packs"",
                ""data_type"": ""_text"",
                ""is_nullable"": true,
                ""default_value"": ""'{}'::text[]""
            },
            {
                ""column"": ""purchased_crop_packs"",
                ""data_type"": ""_text"",
                ""is_nullable"": true,
                ""default_value"": ""'{}'::text[]""
            },
            {
                ""column"": ""is_subsidized"",
                ""data_type"": ""bool"",
                ""is_nullable"": false,
                ""default_value"": ""false""
            },
            {
                ""column"": ""unlock_all_crops"",
                ""data_type"": ""bool"",
                ""is_nullable"": false,
                ""default_value"": ""false""
            }
        ],
        ""support_tickets"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""user_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""user_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""user_email"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""ticket_type"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""subject"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""message"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""status"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": ""'open'::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""now()""
            }
        ],
        ""training_records"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""employee_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""module_title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""completed_at"",
                ""data_type"": ""date"",
                ""is_nullable"": false,
                ""default_value"": ""CURRENT_DATE""
            },
            {
                ""column"": ""status"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": ""'Verified'::text""
            },
            {
                ""column"": ""supervisor_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""signature_url"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""training_type"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Individual'::text""
            },
            {
                ""column"": ""employee_number"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""gender"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""batch_session_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""supervisor_signature_data"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""employee_signature_data"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            }
        ],
        ""corporate_partners"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""slug"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""logo_url"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""sponsored_crop_pack"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""contact_email"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            }
        ],
        ""user_video_progress"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""user_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""video_id"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""video_title"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""progress_seconds"",
                ""data_type"": ""numeric"",
                ""is_nullable"": false,
                ""default_value"": ""0""
            },
            {
                ""column"": ""duration_seconds"",
                ""data_type"": ""numeric"",
                ""is_nullable"": false,
                ""default_value"": ""0""
            },
            {
                ""column"": ""percentage"",
                ""data_type"": ""numeric"",
                ""is_nullable"": false,
                ""default_value"": ""0""
            },
            {
                ""column"": ""is_completed"",
                ""data_type"": ""bool"",
                ""is_nullable"": true,
                ""default_value"": ""false""
            },
            {
                ""column"": ""updated_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""timezone('utc'::text, now())""
            }
        ],
        ""sandbox_jsonb_backup"": [
            {
                ""column"": ""table_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""row_id"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""column_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""original_value"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""backed_up_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""now()""
            }
        ],
        ""baseline_ra_templates"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""category"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""regulation_reference"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""review_interval_months"",
                ""data_type"": ""int4"",
                ""is_nullable"": true,
                ""default_value"": ""12""
            },
            {
                ""column"": ""hazards_register"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            }
        ],
        ""partner_portal_tokens"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""partner_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""token"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": ""(gen_random_uuid())::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""expires_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""(now() + '90 days'::interval)""
            },
            {
                ""column"": ""revoked_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": null
            }
        ],
        ""partner_grower_registry"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""partner_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""grower_code"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""company_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""contact_email"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""is_active"",
                ""data_type"": ""bool"",
                ""is_nullable"": true,
                ""default_value"": ""true""
            },
            {
                ""column"": ""claimed_by_company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""claimed_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            }
        ],
        ""company_risk_assessments"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""template_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""work_area"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""equipment_id"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""assessor_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""assessment_date"",
                ""data_type"": ""date"",
                ""is_nullable"": false,
                ""default_value"": ""CURRENT_DATE""
            },
            {
                ""column"": ""review_due_date"",
                ""data_type"": ""date"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""risk_items"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""ppe_verified"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""assessor_signature"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""status"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Active'::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""pre_use_verified"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": ""'[]'::jsonb""
            }
        ],
        ""processor_referral_leads"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""user_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""crop_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""processor_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""status"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": ""'pending'::text""
            }
        ],
        ""crop_pack_addon_purchases"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""crop_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""paystack_ref"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""purchased_by"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""now()""
            }
        ],
        ""risk_assessment_templates"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""sub_tag"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""hazards"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""required_ppe"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""pre_use_checks"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""safe_work_procedures"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""emergency_procedures"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""curriculum_slug"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            }
        ],
        ""company_baseline_assessments"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""template_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""title"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""category"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""assessment_date"",
                ""data_type"": ""date"",
                ""is_nullable"": false,
                ""default_value"": ""CURRENT_DATE""
            },
            {
                ""column"": ""review_due_date"",
                ""data_type"": ""date"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""designated_person_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""designated_person_signature"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""hazards_register"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": false,
                ""default_value"": ""'[]'::jsonb""
            },
            {
                ""column"": ""status"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": ""'Active'::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": ""now()""
            }
        ],
        ""partner_supply_chain_metrics"": [
            {
                ""column"": ""partner_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""partner_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""company_name"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""grower_code"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""claimed_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""is_subsidized"",
                ""data_type"": ""bool"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""total_training_records_90d"",
                ""data_type"": ""int8"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""distinct_modules_completed"",
                ""data_type"": ""int8"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""last_training_at"",
                ""data_type"": ""date"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""is_dark_supplier"",
                ""data_type"": ""bool"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""baseline_reviews_overdue"",
                ""data_type"": ""int8"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""baseline_reviews_total"",
                ""data_type"": ""int8"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""gender_mix_suppressed_under_5"",
                ""data_type"": ""jsonb"",
                ""is_nullable"": true,
                ""default_value"": null
            }
        ],
        ""crop_pack_addon_subscriptions"": [
            {
                ""column"": ""id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": ""gen_random_uuid()""
            },
            {
                ""column"": ""company_id"",
                ""data_type"": ""uuid"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""crop_name"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": null
            },
            {
                ""column"": ""paystack_subscription_code"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""paystack_email_token"",
                ""data_type"": ""text"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""status"",
                ""data_type"": ""text"",
                ""is_nullable"": false,
                ""default_value"": ""'active'::text""
            },
            {
                ""column"": ""created_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": false,
                ""default_value"": ""now()""
            },
            {
                ""column"": ""cancellation_requested_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": null
            },
            {
                ""column"": ""cancelled_at"",
                ""data_type"": ""timestamptz"",
                ""is_nullable"": true,
                ""default_value"": null
            }
        ]
    },
    ""rls_status"": [
        {
            ""table"": ""profiles"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""companies"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""corporate_partners"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""partner_grower_registry"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""company_baseline_assessments"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""partner_portal_tokens"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""baseline_ra_templates"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""training_records"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""sandbox_jsonb_backup"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""crop_pack_addon_purchases"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""sops"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""company_risk_assessments"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""user_video_progress"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""risk_assessment_templates"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""crop_pack_addon_subscriptions"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""processor_referral_leads"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""support_tickets"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        },
        {
            ""table"": ""videos"",
            ""rls_forced"": false,
            ""rls_enabled"": true
        }
    ],
    ""foreign_keys"": [
        {
            ""table"": ""profiles"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""profiles_company_id_fkey""
        },
        {
            ""table"": ""videos"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""videos_company_id_fkey""
        },
        {
            ""table"": ""training_records"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""training_records_company_id_fkey""
        },
        {
            ""table"": ""processor_referral_leads"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""processor_referral_leads_company_id_fkey""
        },
        {
            ""table"": ""sops"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""sops_company_id_fkey""
        },
        {
            ""table"": ""partner_grower_registry"",
            ""column"": ""partner_id"",
            ""foreign_table"": ""corporate_partners"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""partner_grower_registry_partner_id_fkey""
        },
        {
            ""table"": ""partner_grower_registry"",
            ""column"": ""claimed_by_company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""partner_grower_registry_claimed_by_company_id_fkey""
        },
        {
            ""table"": ""company_baseline_assessments"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""company_baseline_assessments_company_id_fkey""
        },
        {
            ""table"": ""company_baseline_assessments"",
            ""column"": ""template_id"",
            ""foreign_table"": ""baseline_ra_templates"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""company_baseline_assessments_template_id_fkey""
        },
        {
            ""table"": ""crop_pack_addon_purchases"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""crop_pack_addon_purchases_company_id_fkey""
        },
        {
            ""table"": ""crop_pack_addon_purchases"",
            ""column"": ""purchased_by"",
            ""foreign_table"": ""profiles"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""crop_pack_addon_purchases_purchased_by_fkey""
        },
        {
            ""table"": ""company_risk_assessments"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""company_risk_assessments_company_id_fkey""
        },
        {
            ""table"": ""company_risk_assessments"",
            ""column"": ""template_id"",
            ""foreign_table"": ""risk_assessment_templates"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""company_risk_assessments_template_id_fkey""
        },
        {
            ""table"": ""crop_pack_addon_subscriptions"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""crop_pack_addon_subscriptions_company_id_fkey""
        },
        {
            ""table"": ""partner_portal_tokens"",
            ""column"": ""partner_id"",
            ""foreign_table"": ""corporate_partners"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""partner_portal_tokens_partner_id_fkey""
        },
        {
            ""table"": ""support_tickets"",
            ""column"": ""company_id"",
            ""foreign_table"": ""companies"",
            ""foreign_column"": ""id"",
            ""constraint_name"": ""support_tickets_company_id_fkey""
        }
    ],
    ""rls_policies"": [
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""profiles"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Admins can update company member profiles"",
            ""using_clause"": ""(EXISTS ( SELECT 1\n   FROM profiles admin_p\n  WHERE ((admin_p.id = auth.uid()) AND (admin_p.company_id = profiles.company_id) AND ((lower(admin_p.role) ~~ '%admin%'::text) OR (lower(admin_p.role) = 'master admin'::text)))))"",
            ""with_check_clause"": ""true""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""profiles"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Allow self insert on profiles"",
            ""using_clause"": null,
            ""with_check_clause"": ""(auth.uid() = id)""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""profiles"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Allow self update on profiles"",
            ""using_clause"": ""(auth.uid() = id)"",
            ""with_check_clause"": ""(auth.uid() = id)""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""profiles"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Allow users to update their profiles"",
            ""using_clause"": ""(auth.uid() = id)"",
            ""with_check_clause"": ""(auth.uid() = id)""
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""profiles"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can insert their own profile"",
            ""using_clause"": null,
            ""with_check_clause"": ""(auth.uid() = id)""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""profiles"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Users can update own profile"",
            ""using_clause"": ""(auth.uid() = id)"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""profiles"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Users can update their own profile"",
            ""using_clause"": ""(auth.uid() = id)"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""profiles"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view profiles in same company"",
            ""using_clause"": ""((id = auth.uid()) OR (company_id = get_my_company_id()))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""companies"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Admins can update own company"",
            ""using_clause"": ""(id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": ""(id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))""
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""companies"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Allow insert on companies during registration"",
            ""using_clause"": null,
            ""with_check_clause"": ""true""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""companies"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Allow members to update their company"",
            ""using_clause"": ""(id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": ""(id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""companies"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view own company"",
            ""using_clause"": ""(id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""corporate_partners"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Allow read corporate partners"",
            ""using_clause"": ""true"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""partner_grower_registry"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view their own company's claimed grower codes"",
            ""using_clause"": ""(claimed_by_company_id = get_my_company_id())"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""company_baseline_assessments"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can insert own company baseline assessments"",
            ""using_clause"": null,
            ""with_check_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""company_baseline_assessments"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Users can update own company baseline assessments"",
            ""using_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""company_baseline_assessments"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view own company baseline assessments"",
            ""using_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""baseline_ra_templates"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Allow authenticated users to read baseline templates"",
            ""using_clause"": ""true"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""training_records"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can insert company training records"",
            ""using_clause"": null,
            ""with_check_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))""
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""training_records"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view company training records"",
            ""using_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""sops"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Allow users to view accessible SOPs"",
            ""using_clause"": ""((company_id IS NULL) OR (company_id = ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())\n LIMIT 1)))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""company_risk_assessments"",
            ""command"": ""ALL"",
            ""policy_name"": ""Tenants can view and insert own risk assessments"",
            ""using_clause"": ""(company_id = ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""company_risk_assessments"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can insert company risk assessments"",
            ""using_clause"": null,
            ""with_check_clause"": ""((company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid()))) OR (company_id IS NULL))""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""company_risk_assessments"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view company risk assessments"",
            ""using_clause"": ""((company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid()))) OR (company_id IS NULL))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""user_video_progress"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can insert own video progress"",
            ""using_clause"": null,
            ""with_check_clause"": ""(auth.uid() = user_id)""
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""user_video_progress"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can insert/update own video progress"",
            ""using_clause"": null,
            ""with_check_clause"": ""(auth.uid() = user_id)""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""user_video_progress"",
            ""command"": ""UPDATE"",
            ""policy_name"": ""Users can update own video progress"",
            ""using_clause"": ""(auth.uid() = user_id)"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""user_video_progress"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view own video progress"",
            ""using_clause"": ""(auth.uid() = user_id)"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""public""
            ],
            ""table"": ""risk_assessment_templates"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Allow read access to all users"",
            ""using_clause"": ""true"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""crop_pack_addon_subscriptions"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view own company addon subscriptions"",
            ""using_clause"": ""(company_id = get_my_company_id())"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""processor_referral_leads"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can view own company referral leads"",
            ""using_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""support_tickets"",
            ""command"": ""INSERT"",
            ""policy_name"": ""Users can create support tickets"",
            ""using_clause"": null,
            ""with_check_clause"": ""(auth.uid() = user_id)""
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""support_tickets"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Users can read company support tickets"",
            ""using_clause"": ""(company_id IN ( SELECT profiles.company_id\n   FROM profiles\n  WHERE (profiles.id = auth.uid())))"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""authenticated""
            ],
            ""table"": ""videos"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Authenticated users can view videos"",
            ""using_clause"": ""true"",
            ""with_check_clause"": null
        },
        {
            ""roles"": [
                ""anon"",
                ""authenticated""
            ],
            ""table"": ""videos"",
            ""command"": ""SELECT"",
            ""policy_name"": ""Public can view master catalog videos"",
            ""using_clause"": ""(company_id IS NULL)"",
            ""with_check_clause"": null
        }
    ],
    ""custom_functions"": [
        {
            ""return_type"": ""jsonb"",
            ""function_name"": ""validate_grower_code""
        },
        {
            ""return_type"": ""uuid"",
            ""function_name"": ""provision_company_subscription""
        },
        {
            ""return_type"": ""void"",
            ""function_name"": ""submit_processor_referral""
        },
        {
            ""return_type"": ""jsonb"",
            ""function_name"": ""upgrade_company_tier""
        },
        {
            ""return_type"": ""jsonb"",
            ""function_name"": ""get_partner_portal_data""
        },
        {
            ""return_type"": ""jsonb"",
            ""function_name"": ""claim_additional_grower_subsidy""
        },
        {
            ""return_type"": ""jsonb"",
            ""function_name"": ""purchase_crop_pack_addon""
        },
        {
            ""return_type"": ""record"",
            ""function_name"": ""provision_company_baseline_register""
        },
        {
            ""return_type"": ""uuid"",
            ""function_name"": ""get_my_company_id""
        },
        {
            ""return_type"": ""jsonb"",
            ""function_name"": ""remove_team_member""
        },
        {
            ""return_type"": ""trigger"",
            ""function_name"": ""sync_profile_to_auth_meta""
        }
    ]
}"
---

## 2. Storage Buckets & Storage RLS Policies
bucket_id,folder,subfolder,file_name,extension,tree_view,full_storage_path,created_at
sops,corporate_partners,Test-Banana,sop_banana_desuckering.docx,docx,sops/corporate_partners/Test-Banana -> sop_banana_desuckering.docx,corporate_partners/Test-Banana/sop_banana_desuckering.docx,2026-09-25 20:17:40.686882+00
sops,corporate_partners,Test-Banana,sop_banana_fertilizer_application.docx,docx,sops/corporate_partners/Test-Banana -> sop_banana_fertilizer_application.docx,corporate_partners/Test-Banana/sop_banana_fertilizer_application.docx,2026-09-25 20:17:40.900949+00
sops,corporate_partners,Test-Banana,sop_banana_planting.docx,docx,sops/corporate_partners/Test-Banana -> sop_banana_planting.docx,corporate_partners/Test-Banana/sop_banana_planting.docx,2026-09-25 20:17:40.69303+00
sops,corporate_partners,Test-Banana,sop_banana_propping.docx,docx,sops/corporate_partners/Test-Banana -> sop_banana_propping.docx,corporate_partners/Test-Banana/sop_banana_propping.docx,2026-09-25 20:17:40.724919+00
sops,corporate_partners,Test-Mac,sop_employee_allergens.docx,docx,sops/corporate_partners/Test-Mac -> sop_employee_allergens.docx,corporate_partners/Test-Mac/sop_employee_allergens.docx,2026-09-25 20:17:40.623642+00
sops,corporate_partners,Test-Mac,sop_macadamia_boiler.docx,docx,sops/corporate_partners/Test-Mac -> sop_macadamia_boiler.docx,corporate_partners/Test-Mac/sop_macadamia_boiler.docx,2026-09-25 20:17:40.52255+00
sops,corporate_partners,Test-Mac,sop_macadamia_chemical_spraying.docx,docx,sops/corporate_partners/Test-Mac -> sop_macadamia_chemical_spraying.docx,corporate_partners/Test-Mac/sop_macadamia_chemical_spraying.docx,2026-09-25 20:17:40.300688+00
sops,corporate_partners,Test-Mac,sop_macadamia_dehusking.docx,docx,sops/corporate_partners/Test-Mac -> sop_macadamia_dehusking.docx,corporate_partners/Test-Mac/sop_macadamia_dehusking.docx,2026-09-25 20:17:39.246489+00
sops,corporate_partners,Test-Mac,sop_macadamia_drying.docx,docx,sops/corporate_partners/Test-Mac -> sop_macadamia_drying.docx,corporate_partners/Test-Mac/sop_macadamia_drying.docx,2026-09-25 20:17:40.644686+00
sops,corporate_partners,Test-Mac,sop_macadamia_sorting.docx,docx,sops/corporate_partners/Test-Mac -> sop_macadamia_sorting.docx,corporate_partners/Test-Mac/sop_macadamia_sorting.docx,2026-09-25 20:17:40.483837+00
sops,corporate_partners,Test-Mac,sop_macadamia_storage.docx,docx,sops/corporate_partners/Test-Mac -> sop_macadamia_storage.docx,corporate_partners/Test-Mac/sop_macadamia_storage.docx,2026-09-25 20:17:39.182811+00
sops,doveton_farm,null,sop_angle_grinder.docx,docx,sops/doveton_farm -> sop_angle_grinder.docx,doveton_farm/sop_angle_grinder.docx,2026-09-25 20:17:30.804423+00
sops,doveton_farm,null,sop_banana_desuckering.docx,docx,sops/doveton_farm -> sop_banana_desuckering.docx,doveton_farm/sop_banana_desuckering.docx,2026-09-25 20:17:30.62856+00
sops,doveton_farm,null,sop_banana_fertilizer_application.docx,docx,sops/doveton_farm -> sop_banana_fertilizer_application.docx,doveton_farm/sop_banana_fertilizer_application.docx,2026-09-25 20:17:30.634679+00
sops,doveton_farm,null,sop_banana_propping.docx,docx,sops/doveton_farm -> sop_banana_propping.docx,doveton_farm/sop_banana_propping.docx,2026-09-25 20:17:29.716067+00
sops,doveton_farm,null,sop_brush_cutter.docx,docx,sops/doveton_farm -> sop_brush_cutter.docx,doveton_farm/sop_brush_cutter.docx,2026-09-25 20:17:29.739681+00
sops,doveton_farm,null,sop_chainsaw.docx,docx,sops/doveton_farm -> sop_chainsaw.docx,doveton_farm/sop_chainsaw.docx,2026-09-25 20:17:30.689627+00
sops,doveton_farm,null,sop_electrical_hazards.docx,docx,sops/doveton_farm -> sop_electrical_hazards.docx,doveton_farm/sop_electrical_hazards.docx,2026-09-25 20:17:30.767326+00
sops,doveton_farm,null,sop_farm_noise.docx,docx,sops/doveton_farm -> sop_farm_noise.docx,doveton_farm/sop_farm_noise.docx,2026-09-25 20:17:29.681836+00
sops,doveton_farm,null,sop_farm_saw.docx,docx,sops/doveton_farm -> sop_farm_saw.docx,doveton_farm/sop_farm_saw.docx,2026-09-25 20:17:29.695272+00
sops,doveton_farm,null,sop_general_farm_employees.docx,docx,sops/doveton_farm -> sop_general_farm_employees.docx,doveton_farm/sop_general_farm_employees.docx,2026-09-25 20:17:30.647247+00
sops,doveton_farm,null,sop_irrigation_manager.docx,docx,sops/doveton_farm -> sop_irrigation_manager.docx,doveton_farm/sop_irrigation_manager.docx,2026-09-25 20:17:29.684599+00
sops,doveton_farm,null,sop_irrigation_pump_house.docx,docx,sops/doveton_farm -> sop_irrigation_pump_house.docx,doveton_farm/sop_irrigation_pump_house.docx,2026-09-25 20:17:30.524113+00
sops,doveton_farm,null,sop_macadamia_boiler.docx,docx,sops/doveton_farm -> sop_macadamia_boiler.docx,doveton_farm/sop_macadamia_boiler.docx,2026-09-25 20:17:29.785304+00
sops,doveton_farm,null,sop_macadamia_chemical_spraying.docx,docx,sops/doveton_farm -> sop_macadamia_chemical_spraying.docx,doveton_farm/sop_macadamia_chemical_spraying.docx,2026-09-25 20:17:30.652784+00
sops,doveton_farm,null,sop_macadamia_dehusking.docx,docx,sops/doveton_farm -> sop_macadamia_dehusking.docx,doveton_farm/sop_macadamia_dehusking.docx,2026-09-25 20:17:29.693163+00
sops,doveton_farm,null,sop_macadamia_drying.docx,docx,sops/doveton_farm -> sop_macadamia_drying.docx,doveton_farm/sop_macadamia_drying.docx,2026-09-25 20:17:30.65198+00
sops,doveton_farm,null,sop_macadamia_sorting.docx,docx,sops/doveton_farm -> sop_macadamia_sorting.docx,doveton_farm/sop_macadamia_sorting.docx,2026-09-25 20:17:31.612803+00
sops,doveton_farm,null,sop_macadamia_storage.docx,docx,sops/doveton_farm -> sop_macadamia_storage.docx,doveton_farm/sop_macadamia_storage.docx,2026-09-25 20:17:29.755924+00
sops,doveton_farm,null,sop_senior_farm_manager.docx,docx,sops/doveton_farm -> sop_senior_farm_manager.docx,doveton_farm/sop_senior_farm_manager.docx,2026-09-25 20:17:29.658383+00
sops,doveton_farm,null,sop_tractor_operation.docx,docx,sops/doveton_farm -> sop_tractor_operation.docx,doveton_farm/sop_tractor_operation.docx,2026-09-25 20:17:30.714984+00
sops,doveton_farm,null,sop_workshop_manager.docx,docx,sops/doveton_farm -> sop_workshop_manager.docx,doveton_farm/sop_workshop_manager.docx,2026-09-25 20:17:29.730388+00
sops,elliott_farm,null,sop_angle_grinder.docx,docx,sops/elliott_farm -> sop_angle_grinder.docx,elliott_farm/sop_angle_grinder.docx,2026-09-25 20:17:34.185893+00
sops,elliott_farm,null,sop_banana_desuckering.docx,docx,sops/elliott_farm -> sop_banana_desuckering.docx,elliott_farm/sop_banana_desuckering.docx,2026-09-25 20:17:34.184023+00
sops,elliott_farm,null,sop_banana_fertilizer_application.docx,docx,sops/elliott_farm -> sop_banana_fertilizer_application.docx,elliott_farm/sop_banana_fertilizer_application.docx,2026-09-25 20:17:33.227265+00
sops,elliott_farm,null,sop_banana_planting.docx,docx,sops/elliott_farm -> sop_banana_planting.docx,elliott_farm/sop_banana_planting.docx,2026-09-25 20:17:31.805236+00
sops,elliott_farm,null,sop_banana_propping.docx,docx,sops/elliott_farm -> sop_banana_propping.docx,elliott_farm/sop_banana_propping.docx,2026-09-25 20:17:31.880372+00
sops,elliott_farm,null,sop_band_prop_saw.docx,docx,sops/elliott_farm -> sop_band_prop_saw.docx,elliott_farm/sop_band_prop_saw.docx,2026-09-25 20:17:33.21746+00
sops,elliott_farm,null,sop_brush_cutter.docx,docx,sops/elliott_farm -> sop_brush_cutter.docx,elliott_farm/sop_brush_cutter.docx,2026-09-25 20:17:31.797174+00
sops,elliott_farm,null,sop_chainsaw.docx,docx,sops/elliott_farm -> sop_chainsaw.docx,elliott_farm/sop_chainsaw.docx,2026-09-25 20:17:33.198493+00
sops,elliott_farm,null,sop_farm_noise.docx,docx,sops/elliott_farm -> sop_farm_noise.docx,elliott_farm/sop_farm_noise.docx,2026-09-25 20:17:31.793279+00
sops,elliott_farm,null,sop_farm_saw.docx,docx,sops/elliott_farm -> sop_farm_saw.docx,elliott_farm/sop_farm_saw.docx,2026-09-25 20:17:31.895094+00
sops,elliott_farm,null,sop_general_farm_employees.docx,docx,sops/elliott_farm -> sop_general_farm_employees.docx,elliott_farm/sop_general_farm_employees.docx,2026-09-25 20:17:33.196072+00
sops,elliott_farm,null,sop_irrigation_manager.docx,docx,sops/elliott_farm -> sop_irrigation_manager.docx,elliott_farm/sop_irrigation_manager.docx,2026-09-25 20:17:33.187335+00
sops,elliott_farm,null,sop_irrigation_pump_house.docx,docx,sops/elliott_farm -> sop_irrigation_pump_house.docx,elliott_farm/sop_irrigation_pump_house.docx,2026-09-25 20:17:33.225575+00
sops,elliott_farm,null,sop_macadamia_boiler.docx,docx,sops/elliott_farm -> sop_macadamia_boiler.docx,elliott_farm/sop_macadamia_boiler.docx,2026-09-25 20:17:33.129268+00
sops,elliott_farm,null,sop_macadamia_chemical_spraying.docx,docx,sops/elliott_farm -> sop_macadamia_chemical_spraying.docx,elliott_farm/sop_macadamia_chemical_spraying.docx,2026-09-25 20:17:33.231829+00
sops,elliott_farm,null,sop_macadamia_dehusking.docx,docx,sops/elliott_farm -> sop_macadamia_dehusking.docx,elliott_farm/sop_macadamia_dehusking.docx,2026-09-25 20:17:31.942547+00
sops,elliott_farm,null,sop_macadamia_drying.docx,docx,sops/elliott_farm -> sop_macadamia_drying.docx,elliott_farm/sop_macadamia_drying.docx,2026-09-25 20:17:34.212934+00
sops,elliott_farm,null,sop_macadamia_sorting.docx,docx,sops/elliott_farm -> sop_macadamia_sorting.docx,elliott_farm/sop_macadamia_sorting.docx,2026-09-25 20:17:34.223586+00
sops,elliott_farm,null,sop_macadamia_storage.docx,docx,sops/elliott_farm -> sop_macadamia_storage.docx,elliott_farm/sop_macadamia_storage.docx,2026-09-25 20:17:32.039033+00
sops,elliott_farm,null,sop_oxy_acetylene.docx,docx,sops/elliott_farm -> sop_oxy_acetylene.docx,elliott_farm/sop_oxy_acetylene.docx,2026-09-25 20:17:34.174857+00
sops,elliott_farm,null,sop_senior_farm_manager.docx,docx,sops/elliott_farm -> sop_senior_farm_manager.docx,elliott_farm/sop_senior_farm_manager.docx,2026-09-25 20:17:31.993661+00
sops,elliott_farm,null,sop_tractor_operation.docx,docx,sops/elliott_farm -> sop_tractor_operation.docx,elliott_farm/sop_tractor_operation.docx,2026-09-25 20:17:33.224997+00
sops,elliott_farm,null,sop_welding.docx,docx,sops/elliott_farm -> sop_welding.docx,elliott_farm/sop_welding.docx,2026-09-25 20:17:33.200001+00
sops,elliott_farm,null,sop_workshop_manager.docx,docx,sops/elliott_farm -> sop_workshop_manager.docx,elliott_farm/sop_workshop_manager.docx,2026-09-25 20:17:31.987681+00
sops,outlook_farm,null,sop_angle_grinder.docx,docx,sops/outlook_farm -> sop_angle_grinder.docx,outlook_farm/sop_angle_grinder.docx,2026-09-25 20:17:36.633305+00
sops,outlook_farm,null,sop_banana_desuckering.docx,docx,sops/outlook_farm -> sop_banana_desuckering.docx,outlook_farm/sop_banana_desuckering.docx,2026-09-25 20:17:36.630788+00
sops,outlook_farm,null,sop_banana_fertilizer_application.docx,docx,sops/outlook_farm -> sop_banana_fertilizer_application.docx,outlook_farm/sop_banana_fertilizer_application.docx,2026-09-25 20:17:36.616499+00
sops,outlook_farm,null,sop_banana_propping.docx,docx,sops/outlook_farm -> sop_banana_propping.docx,outlook_farm/sop_banana_propping.docx,2026-09-25 20:17:33.94067+00
sops,outlook_farm,null,sop_band_prop_saw.docx,docx,sops/outlook_farm -> sop_band_prop_saw.docx,outlook_farm/sop_band_prop_saw.docx,2026-09-25 20:17:36.629624+00
sops,outlook_farm,null,sop_brush_cutter.docx,docx,sops/outlook_farm -> sop_brush_cutter.docx,outlook_farm/sop_brush_cutter.docx,2026-09-25 20:17:33.953482+00
sops,outlook_farm,null,sop_chainsaw.docx,docx,sops/outlook_farm -> sop_chainsaw.docx,outlook_farm/sop_chainsaw.docx,2026-09-25 20:17:34.982897+00
sops,outlook_farm,null,sop_electrical_hazards.docx,docx,sops/outlook_farm -> sop_electrical_hazards.docx,outlook_farm/sop_electrical_hazards.docx,2026-09-25 20:17:34.957725+00
sops,outlook_farm,null,sop_farm_noise.docx,docx,sops/outlook_farm -> sop_farm_noise.docx,outlook_farm/sop_farm_noise.docx,2026-09-25 20:17:34.115408+00
sops,outlook_farm,null,sop_farm_saw.docx,docx,sops/outlook_farm -> sop_farm_saw.docx,outlook_farm/sop_farm_saw.docx,2026-09-25 20:17:33.980408+00
sops,outlook_farm,null,sop_general_farm_employees.docx,docx,sops/outlook_farm -> sop_general_farm_employees.docx,outlook_farm/sop_general_farm_employees.docx,2026-09-25 20:17:36.624582+00
sops,outlook_farm,null,sop_irrigation_manager.docx,docx,sops/outlook_farm -> sop_irrigation_manager.docx,outlook_farm/sop_irrigation_manager.docx,2026-09-25 20:17:34.961291+00
sops,outlook_farm,null,sop_irrigation_pump_house.docx,docx,sops/outlook_farm -> sop_irrigation_pump_house.docx,outlook_farm/sop_irrigation_pump_house.docx,2026-09-25 20:17:36.64005+00
sops,outlook_farm,null,sop_macadamia_boiler.docx,docx,sops/outlook_farm -> sop_macadamia_boiler.docx,outlook_farm/sop_macadamia_boiler.docx,2026-09-25 20:17:34.973543+00
sops,outlook_farm,null,sop_macadamia_chemical_spraying.docx,docx,sops/outlook_farm -> sop_macadamia_chemical_spraying.docx,outlook_farm/sop_macadamia_chemical_spraying.docx,2026-09-25 20:17:34.968943+00
sops,outlook_farm,null,sop_macadamia_dehusking.docx,docx,sops/outlook_farm -> sop_macadamia_dehusking.docx,outlook_farm/sop_macadamia_dehusking.docx,2026-09-25 20:17:34.130627+00
sops,outlook_farm,null,sop_macadamia_drying.docx,docx,sops/outlook_farm -> sop_macadamia_drying.docx,outlook_farm/sop_macadamia_drying.docx,2026-09-25 20:17:36.639335+00
sops,outlook_farm,null,sop_macadamia_sorting.docx,docx,sops/outlook_farm -> sop_macadamia_sorting.docx,outlook_farm/sop_macadamia_sorting.docx,2026-09-25 20:17:36.611952+00
sops,outlook_farm,null,sop_macadamia_storage.docx,docx,sops/outlook_farm -> sop_macadamia_storage.docx,outlook_farm/sop_macadamia_storage.docx,2026-09-25 20:17:34.974496+00
sops,outlook_farm,null,sop_oxy_acetylene.docx,docx,sops/outlook_farm -> sop_oxy_acetylene.docx,outlook_farm/sop_oxy_acetylene.docx,2026-09-25 20:17:36.639166+00
sops,outlook_farm,null,sop_senior_farm_manager.docx,docx,sops/outlook_farm -> sop_senior_farm_manager.docx,outlook_farm/sop_senior_farm_manager.docx,2026-09-25 20:17:34.97719+00
sops,outlook_farm,null,sop_tractor_operation.docx,docx,sops/outlook_farm -> sop_tractor_operation.docx,outlook_farm/sop_tractor_operation.docx,2026-09-25 20:17:34.962439+00
sops,outlook_farm,null,sop_welding.docx,docx,sops/outlook_farm -> sop_welding.docx,outlook_farm/sop_welding.docx,2026-09-25 20:17:35.824764+00
sops,outlook_farm,null,sop_workshop_manager.docx,docx,sops/outlook_farm -> sop_workshop_manager.docx,outlook_farm/sop_workshop_manager.docx,2026-09-25 20:17:34.986298+00
sops,simple_solutions,null,sop_angle_grinder.docx,docx,sops/simple_solutions -> sop_angle_grinder.docx,simple_solutions/sop_angle_grinder.docx,2026-09-25 20:17:39.050427+00
sops,simple_solutions,null,sop_banana_desuckering.docx,docx,sops/simple_solutions -> sop_banana_desuckering.docx,simple_solutions/sop_banana_desuckering.docx,2026-09-25 20:17:39.030997+00
sops,simple_solutions,null,sop_banana_fertilizer_application.docx,docx,sops/simple_solutions -> sop_banana_fertilizer_application.docx,simple_solutions/sop_banana_fertilizer_application.docx,2026-09-25 20:17:38.286794+00
sops,simple_solutions,null,sop_banana_planting.docx,docx,sops/simple_solutions -> sop_banana_planting.docx,simple_solutions/sop_banana_planting.docx,2026-09-25 20:17:36.592123+00
sops,simple_solutions,null,sop_banana_propping.docx,docx,sops/simple_solutions -> sop_banana_propping.docx,simple_solutions/sop_banana_propping.docx,2026-09-25 20:17:37.354129+00
sops,simple_solutions,null,sop_band_prop_saw.docx,docx,sops/simple_solutions -> sop_band_prop_saw.docx,simple_solutions/sop_band_prop_saw.docx,2026-09-25 20:17:38.276811+00
sops,simple_solutions,null,sop_brush_cutter.docx,docx,sops/simple_solutions -> sop_brush_cutter.docx,simple_solutions/sop_brush_cutter.docx,2026-09-25 20:17:37.355745+00
sops,simple_solutions,null,sop_chainsaw.docx,docx,sops/simple_solutions -> sop_chainsaw.docx,simple_solutions/sop_chainsaw.docx,2026-09-25 20:17:38.228834+00
sops,simple_solutions,null,sop_citrus_chemical_spraying.docx,docx,sops/simple_solutions -> sop_citrus_chemical_spraying.docx,simple_solutions/sop_citrus_chemical_spraying.docx,2026-09-25 20:17:38.323363+00
sops,simple_solutions,null,sop_citrus_orchard_hygiene.docx,docx,sops/simple_solutions -> sop_citrus_orchard_hygiene.docx,simple_solutions/sop_citrus_orchard_hygiene.docx,2026-09-25 20:17:39.127802+00
sops,simple_solutions,null,sop_citrus_orchard_ladder.docx,docx,sops/simple_solutions -> sop_citrus_orchard_ladder.docx,simple_solutions/sop_citrus_orchard_ladder.docx,2026-09-25 20:17:39.032611+00
sops,simple_solutions,null,sop_citrus_orchard.docx,docx,sops/simple_solutions -> sop_citrus_orchard.docx,simple_solutions/sop_citrus_orchard.docx,2026-09-25 20:17:39.046421+00
sops,simple_solutions,null,sop_electrical_hazards.docx,docx,sops/simple_solutions -> sop_electrical_hazards.docx,simple_solutions/sop_electrical_hazards.docx,2026-09-25 20:17:38.250424+00
sops,simple_solutions,null,sop_farm_noise.docx,docx,sops/simple_solutions -> sop_farm_noise.docx,simple_solutions/sop_farm_noise.docx,2026-09-25 20:17:37.350891+00
sops,simple_solutions,null,sop_farm_saw.docx,docx,sops/simple_solutions -> sop_farm_saw.docx,simple_solutions/sop_farm_saw.docx,2026-09-25 20:17:37.322754+00
sops,simple_solutions,null,sop_general_farm_employees.docx,docx,sops/simple_solutions -> sop_general_farm_employees.docx,simple_solutions/sop_general_farm_employees.docx,2026-09-25 20:17:38.246935+00
sops,simple_solutions,null,sop_irrigation_manager.docx,docx,sops/simple_solutions -> sop_irrigation_manager.docx,simple_solutions/sop_irrigation_manager.docx,2026-09-25 20:17:37.357827+00
sops,simple_solutions,null,sop_irrigation_pump_house.docx,docx,sops/simple_solutions -> sop_irrigation_pump_house.docx,simple_solutions/sop_irrigation_pump_house.docx,2026-09-25 20:17:38.241292+00
sops,simple_solutions,null,sop_macadamia_boiler.docx,docx,sops/simple_solutions -> sop_macadamia_boiler.docx,simple_solutions/sop_macadamia_boiler.docx,2026-09-25 20:17:37.348884+00
sops,simple_solutions,null,sop_macadamia_chemical_spraying.docx,docx,sops/simple_solutions -> sop_macadamia_chemical_spraying.docx,simple_solutions/sop_macadamia_chemical_spraying.docx,2026-09-25 20:17:38.260798+00
sops,simple_solutions,null,sop_macadamia_dehusking.docx,docx,sops/simple_solutions -> sop_macadamia_dehusking.docx,simple_solutions/sop_macadamia_dehusking.docx,2026-09-25 20:17:37.410308+00
sops,simple_solutions,null,sop_macadamia_drying.docx,docx,sops/simple_solutions -> sop_macadamia_drying.docx,simple_solutions/sop_macadamia_drying.docx,2026-09-25 20:17:39.076054+00
sops,simple_solutions,null,sop_macadamia_sorting.docx,docx,sops/simple_solutions -> sop_macadamia_sorting.docx,simple_solutions/sop_macadamia_sorting.docx,2026-09-25 20:17:39.176075+00
sops,simple_solutions,null,sop_macadamia_storage.docx,docx,sops/simple_solutions -> sop_macadamia_storage.docx,simple_solutions/sop_macadamia_storage.docx,2026-09-25 20:17:37.363922+00
sops,simple_solutions,null,sop_oxy_acetylene.docx,docx,sops/simple_solutions -> sop_oxy_acetylene.docx,simple_solutions/sop_oxy_acetylene.docx,2026-09-25 20:17:39.053096+00
sops,simple_solutions,null,sop_senior_farm_manager.docx,docx,sops/simple_solutions -> sop_senior_farm_manager.docx,simple_solutions/sop_senior_farm_manager.docx,2026-09-25 20:17:37.329708+00
sops,simple_solutions,null,sop_tractor_operation.docx,docx,sops/simple_solutions -> sop_tractor_operation.docx,simple_solutions/sop_tractor_operation.docx,2026-09-25 20:17:38.38069+00
sops,simple_solutions,null,sop_welding.docx,docx,sops/simple_solutions -> sop_welding.docx,simple_solutions/sop_welding.docx,2026-09-25 20:17:38.346252+00
sops,simple_solutions,null,sop_workshop_manager.docx,docx,sops/simple_solutions -> sop_workshop_manager.docx,simple_solutions/sop_workshop_manager.docx,2026-09-25 20:17:37.556749+00
thumbnails,corporate_partners,Test-Banana,banana_desuckering.svg,svg,thumbnails/corporate_partners/Test-Banana -> banana_desuckering.svg,corporate_partners/Test-Banana/banana_desuckering.svg,2026-09-25 20:16:01.350215+00
thumbnails,corporate_partners,Test-Banana,banana_fertilizer_application.svg,svg,thumbnails/corporate_partners/Test-Banana -> banana_fertilizer_application.svg,corporate_partners/Test-Banana/banana_fertilizer_application.svg,2026-09-25 20:16:01.442708+00
thumbnails,corporate_partners,Test-Banana,banana_propping.svg,svg,thumbnails/corporate_partners/Test-Banana -> banana_propping.svg,corporate_partners/Test-Banana/banana_propping.svg,2026-09-25 20:16:01.392598+00
thumbnails,corporate_partners,Test-Citrus,citrus_chemical_spraying.svg,svg,thumbnails/corporate_partners/Test-Citrus -> citrus_chemical_spraying.svg,corporate_partners/Test-Citrus/citrus_chemical_spraying.svg,2026-09-25 20:16:00.984589+00
thumbnails,corporate_partners,Test-Citrus,citrus_orchard_hygiene.svg,svg,thumbnails/corporate_partners/Test-Citrus -> citrus_orchard_hygiene.svg,corporate_partners/Test-Citrus/citrus_orchard_hygiene.svg,2026-09-25 20:16:01.033162+00
thumbnails,corporate_partners,Test-Citrus,citrus_orchard_ladder.svg,svg,thumbnails/corporate_partners/Test-Citrus -> citrus_orchard_ladder.svg,corporate_partners/Test-Citrus/citrus_orchard_ladder.svg,2026-09-25 20:16:00.982944+00
thumbnails,corporate_partners,Test-Citrus,citrus_orchard.svg,svg,thumbnails/corporate_partners/Test-Citrus -> citrus_orchard.svg,corporate_partners/Test-Citrus/citrus_orchard.svg,2026-09-25 20:16:00.968616+00
thumbnails,corporate_partners,Test-Mac,employee_allergens.svg,svg,thumbnails/corporate_partners/Test-Mac -> employee_allergens.svg,corporate_partners/Test-Mac/employee_allergens.svg,2026-09-25 20:15:59.760487+00
thumbnails,corporate_partners,Test-Mac,farm_noise.svg,svg,thumbnails/corporate_partners/Test-Mac -> farm_noise.svg,corporate_partners/Test-Mac/farm_noise.svg,2026-09-25 20:15:59.674766+00
thumbnails,corporate_partners,Test-Mac,macadamia_boiler.svg,svg,thumbnails/corporate_partners/Test-Mac -> macadamia_boiler.svg,corporate_partners/Test-Mac/macadamia_boiler.svg,2026-09-25 20:15:59.834265+00
thumbnails,corporate_partners,Test-Mac,macadamia_chemical_spraying.svg,svg,thumbnails/corporate_partners/Test-Mac -> macadamia_chemical_spraying.svg,corporate_partners/Test-Mac/macadamia_chemical_spraying.svg,2026-09-25 20:15:59.717045+00
thumbnails,corporate_partners,Test-Mac,macadamia_dehusking.svg,svg,thumbnails/corporate_partners/Test-Mac -> macadamia_dehusking.svg,corporate_partners/Test-Mac/macadamia_dehusking.svg,2026-09-25 20:15:59.849874+00
thumbnails,corporate_partners,Test-Mac,macadamia_drying.svg,svg,thumbnails/corporate_partners/Test-Mac -> macadamia_drying.svg,corporate_partners/Test-Mac/macadamia_drying.svg,2026-09-25 20:15:59.709685+00
thumbnails,corporate_partners,Test-Mac,macadamia_storage.svg,svg,thumbnails/corporate_partners/Test-Mac -> macadamia_storage.svg,corporate_partners/Test-Mac/macadamia_storage.svg,2026-09-25 20:16:00.062313+00
thumbnails,doveton_farm,null,angle_grinder.svg,svg,thumbnails/doveton_farm -> angle_grinder.svg,doveton_farm/angle_grinder.svg,2026-09-25 20:15:56.675528+00
thumbnails,doveton_farm,null,banana_desuckering.svg,svg,thumbnails/doveton_farm -> banana_desuckering.svg,doveton_farm/banana_desuckering.svg,2026-09-25 20:15:55.54856+00
thumbnails,doveton_farm,null,banana_fertilizer_application.svg,svg,thumbnails/doveton_farm -> banana_fertilizer_application.svg,doveton_farm/banana_fertilizer_application.svg,2026-09-25 20:15:55.717552+00
thumbnails,doveton_farm,null,banana_propping.svg,svg,thumbnails/doveton_farm -> banana_propping.svg,doveton_farm/banana_propping.svg,2026-09-25 20:15:55.468684+00
thumbnails,doveton_farm,null,brush_cutter.svg,svg,thumbnails/doveton_farm -> brush_cutter.svg,doveton_farm/brush_cutter.svg,2026-09-25 20:15:56.563269+00
thumbnails,doveton_farm,null,chainsaw.svg,svg,thumbnails/doveton_farm -> chainsaw.svg,doveton_farm/chainsaw.svg,2026-09-25 20:15:56.567373+00
thumbnails,doveton_farm,null,electrical_hazards.svg,svg,thumbnails/doveton_farm -> electrical_hazards.svg,doveton_farm/electrical_hazards.svg,2026-09-25 20:15:56.507624+00
thumbnails,doveton_farm,null,employee_allergens.svg,svg,thumbnails/doveton_farm -> employee_allergens.svg,doveton_farm/employee_allergens.svg,2026-09-25 20:15:55.466194+00
thumbnails,doveton_farm,null,farm_noise.svg,svg,thumbnails/doveton_farm -> farm_noise.svg,doveton_farm/farm_noise.svg,2026-09-25 20:15:55.622597+00
thumbnails,doveton_farm,null,farm_saw.svg,svg,thumbnails/doveton_farm -> farm_saw.svg,doveton_farm/farm_saw.svg,2026-09-25 20:15:55.49228+00
thumbnails,doveton_farm,null,fertigation_pump_house.svg,svg,thumbnails/doveton_farm -> fertigation_pump_house.svg,doveton_farm/fertigation_pump_house.svg,2026-09-25 20:15:55.489622+00
thumbnails,doveton_farm,null,general_farm_employees.svg,svg,thumbnails/doveton_farm -> general_farm_employees.svg,doveton_farm/general_farm_employees.svg,2026-09-25 20:15:56.532574+00
thumbnails,doveton_farm,null,irrigation_pump_house.svg,svg,thumbnails/doveton_farm -> irrigation_pump_house.svg,doveton_farm/irrigation_pump_house.svg,2026-09-25 20:15:55.514432+00
thumbnails,doveton_farm,null,macadamia_boiler.svg,svg,thumbnails/doveton_farm -> macadamia_boiler.svg,doveton_farm/macadamia_boiler.svg,2026-09-25 20:15:56.625077+00
thumbnails,doveton_farm,null,macadamia_chemical_spraying.svg,svg,thumbnails/doveton_farm -> macadamia_chemical_spraying.svg,doveton_farm/macadamia_chemical_spraying.svg,2026-09-25 20:15:55.477827+00
thumbnails,doveton_farm,null,macadamia_dehusking.svg,svg,thumbnails/doveton_farm -> macadamia_dehusking.svg,doveton_farm/macadamia_dehusking.svg,2026-09-25 20:15:56.576026+00
thumbnails,doveton_farm,null,macadamia_drying.svg,svg,thumbnails/doveton_farm -> macadamia_drying.svg,doveton_farm/macadamia_drying.svg,2026-09-25 20:15:55.431448+00
thumbnails,doveton_farm,null,macadamia_storage.svg,svg,thumbnails/doveton_farm -> macadamia_storage.svg,doveton_farm/macadamia_storage.svg,2026-09-25 20:15:56.533666+00
thumbnails,doveton_farm,null,tractor_logbook.svg,svg,thumbnails/doveton_farm -> tractor_logbook.svg,doveton_farm/tractor_logbook.svg,2026-09-25 20:15:56.479566+00
thumbnails,doveton_farm,null,tractor_operation.svg,svg,thumbnails/doveton_farm -> tractor_operation.svg,doveton_farm/tractor_operation.svg,2026-09-25 20:15:56.541922+00
thumbnails,elliott_farm,null,angle_grinder.svg,svg,thumbnails/elliott_farm -> angle_grinder.svg,elliott_farm/angle_grinder.svg,2026-09-25 20:15:58.403117+00
thumbnails,elliott_farm,null,banana_desuckering.svg,svg,thumbnails/elliott_farm -> banana_desuckering.svg,elliott_farm/banana_desuckering.svg,2026-09-25 20:15:57.432369+00
thumbnails,elliott_farm,null,banana_fertilizer_application.svg,svg,thumbnails/elliott_farm -> banana_fertilizer_application.svg,elliott_farm/banana_fertilizer_application.svg,2026-09-25 20:15:57.623952+00
thumbnails,elliott_farm,null,banana_propping.svg,svg,thumbnails/elliott_farm -> banana_propping.svg,elliott_farm/banana_propping.svg,2026-09-25 20:15:57.43158+00
thumbnails,elliott_farm,null,band_prop_saw.svg,svg,thumbnails/elliott_farm -> band_prop_saw.svg,elliott_farm/band_prop_saw.svg,2026-09-25 20:15:59.248729+00
thumbnails,elliott_farm,null,brush_cutter.svg,svg,thumbnails/elliott_farm -> brush_cutter.svg,elliott_farm/brush_cutter.svg,2026-09-25 20:15:58.398487+00
thumbnails,elliott_farm,null,chainsaw.svg,svg,thumbnails/elliott_farm -> chainsaw.svg,elliott_farm/chainsaw.svg,2026-09-25 20:15:58.494254+00
thumbnails,elliott_farm,null,electrical_hazards.svg,svg,thumbnails/elliott_farm -> electrical_hazards.svg,elliott_farm/electrical_hazards.svg,2026-09-25 20:15:59.226734+00
thumbnails,elliott_farm,null,employee_allergens.svg,svg,thumbnails/elliott_farm -> employee_allergens.svg,elliott_farm/employee_allergens.svg,2026-09-25 20:15:57.43019+00
thumbnails,elliott_farm,null,farm_noise.svg,svg,thumbnails/elliott_farm -> farm_noise.svg,elliott_farm/farm_noise.svg,2026-09-25 20:15:57.503946+00
thumbnails,elliott_farm,null,farm_saw.svg,svg,thumbnails/elliott_farm -> farm_saw.svg,elliott_farm/farm_saw.svg,2026-09-25 20:15:58.369382+00
thumbnails,elliott_farm,null,fertigation_pump_house.svg,svg,thumbnails/elliott_farm -> fertigation_pump_house.svg,elliott_farm/fertigation_pump_house.svg,2026-09-25 20:15:57.521167+00
thumbnails,elliott_farm,null,general_farm_employees.svg,svg,thumbnails/elliott_farm -> general_farm_employees.svg,elliott_farm/general_farm_employees.svg,2026-09-25 20:15:59.240573+00
thumbnails,elliott_farm,null,irrigation_pump_house.svg,svg,thumbnails/elliott_farm -> irrigation_pump_house.svg,elliott_farm/irrigation_pump_house.svg,2026-09-25 20:15:57.480546+00
thumbnails,elliott_farm,null,macadamia_boiler.svg,svg,thumbnails/elliott_farm -> macadamia_boiler.svg,elliott_farm/macadamia_boiler.svg,2026-09-25 20:15:58.480662+00
thumbnails,elliott_farm,null,macadamia_chemical_spraying.svg,svg,thumbnails/elliott_farm -> macadamia_chemical_spraying.svg,elliott_farm/macadamia_chemical_spraying.svg,2026-09-25 20:15:57.590774+00
thumbnails,elliott_farm,null,macadamia_dehusking.svg,svg,thumbnails/elliott_farm -> macadamia_dehusking.svg,elliott_farm/macadamia_dehusking.svg,2026-09-25 20:15:58.395421+00
thumbnails,elliott_farm,null,macadamia_drying.svg,svg,thumbnails/elliott_farm -> macadamia_drying.svg,elliott_farm/macadamia_drying.svg,2026-09-25 20:15:57.563562+00
thumbnails,elliott_farm,null,macadamia_storage.svg,svg,thumbnails/elliott_farm -> macadamia_storage.svg,elliott_farm/macadamia_storage.svg,2026-09-25 20:15:58.39292+00
thumbnails,elliott_farm,null,oxy_acetylene.svg,svg,thumbnails/elliott_farm -> oxy_acetylene.svg,elliott_farm/oxy_acetylene.svg,2026-09-25 20:15:58.471577+00
thumbnails,elliott_farm,null,tractor_logbook.svg,svg,thumbnails/elliott_farm -> tractor_logbook.svg,elliott_farm/tractor_logbook.svg,2026-09-25 20:15:58.376332+00
thumbnails,elliott_farm,null,tractor_operation.svg,svg,thumbnails/elliott_farm -> tractor_operation.svg,elliott_farm/tractor_operation.svg,2026-09-25 20:15:58.380788+00
thumbnails,elliott_farm,null,welding.svg,svg,thumbnails/elliott_farm -> welding.svg,elliott_farm/welding.svg,2026-09-25 20:15:57.584225+00
thumbnails,outlook_farm,null,angle_grinder.svg,svg,thumbnails/outlook_farm -> angle_grinder.svg,outlook_farm/angle_grinder.svg,2026-09-25 20:14:21.009221+00
thumbnails,outlook_farm,null,banana_desuckering.svg,svg,thumbnails/outlook_farm -> banana_desuckering.svg,outlook_farm/banana_desuckering.svg,2026-09-25 20:14:19.99185+00
thumbnails,outlook_farm,null,banana_fertilizer_application.svg,svg,thumbnails/outlook_farm -> banana_fertilizer_application.svg,outlook_farm/banana_fertilizer_application.svg,2026-09-25 20:14:20.206816+00
thumbnails,outlook_farm,null,banana_propping.svg,svg,thumbnails/outlook_farm -> banana_propping.svg,outlook_farm/banana_propping.svg,2026-09-25 20:14:19.954055+00
thumbnails,outlook_farm,null,band_prop_saw.svg,svg,thumbnails/outlook_farm -> band_prop_saw.svg,outlook_farm/band_prop_saw.svg,2026-09-25 20:14:21.923315+00
thumbnails,outlook_farm,null,brush_cutter.svg,svg,thumbnails/outlook_farm -> brush_cutter.svg,outlook_farm/brush_cutter.svg,2026-09-25 20:14:21.001071+00
thumbnails,outlook_farm,null,chainsaw.svg,svg,thumbnails/outlook_farm -> chainsaw.svg,outlook_farm/chainsaw.svg,2026-09-25 20:14:21.00082+00
thumbnails,outlook_farm,null,electrical_hazards.svg,svg,thumbnails/outlook_farm -> electrical_hazards.svg,outlook_farm/electrical_hazards.svg,2026-09-25 20:14:21.892035+00
thumbnails,outlook_farm,null,employee_allergens.svg,svg,thumbnails/outlook_farm -> employee_allergens.svg,outlook_farm/employee_allergens.svg,2026-09-25 20:14:19.594906+00
thumbnails,outlook_farm,null,farm_noise.svg,svg,thumbnails/outlook_farm -> farm_noise.svg,outlook_farm/farm_noise.svg,2026-09-25 20:14:19.972901+00
thumbnails,outlook_farm,null,farm_saw.svg,svg,thumbnails/outlook_farm -> farm_saw.svg,outlook_farm/farm_saw.svg,2026-09-25 20:14:21.035367+00
thumbnails,outlook_farm,null,fertigation_pump_house.svg,svg,thumbnails/outlook_farm -> fertigation_pump_house.svg,outlook_farm/fertigation_pump_house.svg,2026-09-25 20:14:19.91616+00
thumbnails,outlook_farm,null,general_farm_employees.svg,svg,thumbnails/outlook_farm -> general_farm_employees.svg,outlook_farm/general_farm_employees.svg,2026-09-25 20:14:21.887822+00
thumbnails,outlook_farm,null,irrigation_pump_house.svg,svg,thumbnails/outlook_farm -> irrigation_pump_house.svg,outlook_farm/irrigation_pump_house.svg,2026-09-25 20:14:19.86981+00
thumbnails,outlook_farm,null,macadamia_boiler.svg,svg,thumbnails/outlook_farm -> macadamia_boiler.svg,outlook_farm/macadamia_boiler.svg,2026-09-25 20:14:21.13515+00
thumbnails,outlook_farm,null,macadamia_chemical_spraying.svg,svg,thumbnails/outlook_farm -> macadamia_chemical_spraying.svg,outlook_farm/macadamia_chemical_spraying.svg,2026-09-25 20:14:19.658263+00
thumbnails,outlook_farm,null,macadamia_dehusking.svg,svg,thumbnails/outlook_farm -> macadamia_dehusking.svg,outlook_farm/macadamia_dehusking.svg,2026-09-25 20:14:20.986975+00
thumbnails,outlook_farm,null,macadamia_drying.svg,svg,thumbnails/outlook_farm -> macadamia_drying.svg,outlook_farm/macadamia_drying.svg,2026-09-25 20:14:20.008607+00
thumbnails,outlook_farm,null,macadamia_storage.svg,svg,thumbnails/outlook_farm -> macadamia_storage.svg,outlook_farm/macadamia_storage.svg,2026-09-25 20:14:21.034139+00
thumbnails,outlook_farm,null,oxy_acetylene.svg,svg,thumbnails/outlook_farm -> oxy_acetylene.svg,outlook_farm/oxy_acetylene.svg,2026-09-25 20:14:21.016577+00
thumbnails,outlook_farm,null,tractor_logbook.svg,svg,thumbnails/outlook_farm -> tractor_logbook.svg,outlook_farm/tractor_logbook.svg,2026-09-25 20:14:20.967798+00
thumbnails,outlook_farm,null,tractor_operation.svg,svg,thumbnails/outlook_farm -> tractor_operation.svg,outlook_farm/tractor_operation.svg,2026-09-25 20:14:21.029455+00
thumbnails,outlook_farm,null,welding.svg,svg,thumbnails/outlook_farm -> welding.svg,outlook_farm/welding.svg,2026-09-25 20:14:19.562992+00
thumbnails,simple_solutions,null,angle_grinder.svg,svg,thumbnails/simple_solutions -> angle_grinder.svg,simple_solutions/angle_grinder.svg,2026-09-25 20:13:59.031391+00
thumbnails,simple_solutions,null,banana_desuckering.svg,svg,thumbnails/simple_solutions -> banana_desuckering.svg,simple_solutions/banana_desuckering.svg,2026-09-25 20:13:58.188936+00
thumbnails,simple_solutions,null,banana_fertilizer_application.svg,svg,thumbnails/simple_solutions -> banana_fertilizer_application.svg,simple_solutions/banana_fertilizer_application.svg,2026-09-25 20:13:57.892937+00
thumbnails,simple_solutions,null,banana_propping.svg,svg,thumbnails/simple_solutions -> banana_propping.svg,simple_solutions/banana_propping.svg,2026-09-25 20:13:57.954627+00
thumbnails,simple_solutions,null,band_prop_saw.svg,svg,thumbnails/simple_solutions -> band_prop_saw.svg,simple_solutions/band_prop_saw.svg,2026-09-25 20:14:00.137035+00
thumbnails,simple_solutions,null,brush_cutter.svg,svg,thumbnails/simple_solutions -> brush_cutter.svg,simple_solutions/brush_cutter.svg,2026-09-25 20:13:59.043304+00
thumbnails,simple_solutions,null,chainsaw.svg,svg,thumbnails/simple_solutions -> chainsaw.svg,simple_solutions/chainsaw.svg,2026-09-25 20:13:59.033933+00
thumbnails,simple_solutions,null,citrus_chemical_spraying.svg,svg,thumbnails/simple_solutions -> citrus_chemical_spraying.svg,simple_solutions/citrus_chemical_spraying.svg,2026-09-25 20:13:59.065081+00
thumbnails,simple_solutions,null,citrus_orchard_hygiene.svg,svg,thumbnails/simple_solutions -> citrus_orchard_hygiene.svg,simple_solutions/citrus_orchard_hygiene.svg,2026-09-25 20:13:58.183803+00
thumbnails,simple_solutions,null,citrus_orchard_ladder.svg,svg,thumbnails/simple_solutions -> citrus_orchard_ladder.svg,simple_solutions/citrus_orchard_ladder.svg,2026-09-25 20:13:59.949079+00
thumbnails,simple_solutions,null,citrus_orchard.svg,svg,thumbnails/simple_solutions -> citrus_orchard.svg,simple_solutions/citrus_orchard.svg,2026-09-25 20:14:00.099734+00
thumbnails,simple_solutions,null,electrical_hazards.svg,svg,thumbnails/simple_solutions -> electrical_hazards.svg,simple_solutions/electrical_hazards.svg,2026-09-25 20:13:59.971958+00
thumbnails,simple_solutions,null,employee_allergens.svg,svg,thumbnails/simple_solutions -> employee_allergens.svg,simple_solutions/employee_allergens.svg,2026-09-25 20:13:57.89433+00
thumbnails,simple_solutions,null,farm_noise.svg,svg,thumbnails/simple_solutions -> farm_noise.svg,simple_solutions/farm_noise.svg,2026-09-25 20:13:57.879731+00
thumbnails,simple_solutions,null,farm_saw.svg,svg,thumbnails/simple_solutions -> farm_saw.svg,simple_solutions/farm_saw.svg,2026-09-25 20:13:59.033909+00
thumbnails,simple_solutions,null,general_farm_employees.svg,svg,thumbnails/simple_solutions -> general_farm_employees.svg,simple_solutions/general_farm_employees.svg,2026-09-25 20:14:00.146367+00
thumbnails,simple_solutions,null,irrigation_pump_house.svg,svg,thumbnails/simple_solutions -> irrigation_pump_house.svg,simple_solutions/irrigation_pump_house.svg,2026-09-25 20:13:58.184984+00
thumbnails,simple_solutions,null,macadamia_boiler.svg,svg,thumbnails/simple_solutions -> macadamia_boiler.svg,simple_solutions/macadamia_boiler.svg,2026-09-25 20:13:59.015782+00
thumbnails,simple_solutions,null,macadamia_chemical_spraying.svg,svg,thumbnails/simple_solutions -> macadamia_chemical_spraying.svg,simple_solutions/macadamia_chemical_spraying.svg,2026-09-25 20:13:58.194054+00
thumbnails,simple_solutions,null,macadamia_dehusking.svg,svg,thumbnails/simple_solutions -> macadamia_dehusking.svg,simple_solutions/macadamia_dehusking.svg,2026-09-25 20:13:59.072762+00
thumbnails,simple_solutions,null,macadamia_drying.svg,svg,thumbnails/simple_solutions -> macadamia_drying.svg,simple_solutions/macadamia_drying.svg,2026-09-25 20:13:58.16612+00
thumbnails,simple_solutions,null,macadamia_storage.svg,svg,thumbnails/simple_solutions -> macadamia_storage.svg,simple_solutions/macadamia_storage.svg,2026-09-25 20:13:59.15821+00
thumbnails,simple_solutions,null,oxy_acetylene.svg,svg,thumbnails/simple_solutions -> oxy_acetylene.svg,simple_solutions/oxy_acetylene.svg,2026-09-25 20:14:00.030195+00
thumbnails,simple_solutions,null,tractor_logbook.svg,svg,thumbnails/simple_solutions -> tractor_logbook.svg,simple_solutions/tractor_logbook.svg,2026-09-25 20:13:59.059669+00
thumbnails,simple_solutions,null,tractor_operation.svg,svg,thumbnails/simple_solutions -> tractor_operation.svg,simple_solutions/tractor_operation.svg,2026-09-25 20:13:58.970764+00
thumbnails,simple_solutions,null,welding.svg,svg,thumbnails/simple_solutions -> welding.svg,simple_solutions/welding.svg,2026-09-25 20:13:58.25179+00