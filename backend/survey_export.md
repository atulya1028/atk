# Clinical Survey Analysis Report

## Section: Psychosocial Stressors (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_psychosocial_stressors_work_or_academic_pressure] Have you been experiencing any work or academic pressure lately?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_psychosocial_stressors_type_of_pressure] Could you tell us more about the type of pressure you"re facing?
   - Type: **select** | Required: true
   - **Options**:
     - [work] Work
     - [academic_pressure] Academic pressure
     - [both] Both
   - **Logic (Shown If)**:
     - Trigger QID 10 eq 'yes'

### [gen_risk_assessment_screening_psychosocial_stressors_financial_stress] Are you currently dealing with any financial stress?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_psychosocial_stressors_relationship_or_marital_proble] Have you been experiencing any relationship or marital challenges?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_psychosocial_stressors_major_life_changes] Have there been any major life changes recently?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_psychosocial_stressors_major_life_changes_option_to_specify] If comfortable, could you share what changes you"ve experienced?
   - Type: **text** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 14 eq 'yes'

---
## Section: Identifying Data (Type: general)

### [gen_identifying_data_name] Name
   - Type: **text_subfields** | Required: true

### [gen_identifying_data_gender] How would you like to identify your gender?
   - Type: **select** | Required: false
   - Note: _can be avoided if it does not impact test_
   - **Options**:
     - [male] Male
     - [female] Female
     - [other] Other
     - [prefer_not_to_say] Prefer not to say

### [gen_identifying_data_education] What is your highest level of education?
   - Type: **select** | Required: false
   - Note: _can be avoided if it does not impact test_
   - **Options**:
     - [no_formal_education] No formal education
     - [primary_school] Primary school
     - [secondary_school] Secondary school
     - [high_school] High school
     - [diploma_certificate] Diploma/Certificate
     - [bachelors_degree] Bachelor"s degree
     - [masters_degree] Master"s degree
     - [doctoral_degree] Doctoral degree

### [gen_identifying_data_occupation] What is your current occupation or work status?
   - Type: **select** | Required: true
   - Note: _Selection from a list_
   - **Options**:
     - [student] Student
     - [employed_full_time] Employed (Full-time)
     - [employed_part_time] Employed (Part-time)
     - [self_employed] Self-employed
     - [unemployed] Unemployed
     - [retired] Retired
     - [homemaker] Homemaker
     - [unable_to_work] Unable to work

### [gen_identifying_data_marital_status] What is your current relationship status?
   - Type: **select** | Required: true
   - Note: _Selection from a list_
   - **Options**:
     - [single] Single
     - [married] Married
     - [divorced] Divorced
     - [widowed] Widowed
     - [separated] Separated
     - [in_relationship] In a relationship

### [gen_identifying_data_informant_reliability] How would you rate the reliability of the information being provided?
   - Type: **select** | Required: true
   - Note: _Selection from a list_
   - **Options**:
     - [reliable] Reliable
     - [mostly_reliable] Mostly reliable
     - [somewhat_reliable] Somewhat reliable
     - [unreliable] Unreliable
     - [unable_to_assess] Unable to assess

### [gen_identifying_data_relation] What is your relationship to the person being assessed?
   - Type: **select** | Required: true
   - Note: _Selection from a list_
   - **Options**:
     - [self] Self
     - [parent] Parent
     - [spouse_partner] Spouse/Partner
     - [sibling] Sibling
     - [child] Child
     - [friend] Friend
     - [healthcare_provider] Healthcare provider
     - [other] Other

---
## Section: History (Type: benzodiazepine)

### [sub_benzodiazepine_history_drug_name] Which benzodiazepine medication have you been using?
   - Type: **select** | Required: true
   - **Options**:
     - [alprazolam_xanax] Alprazolam (Xanax)
     - [diazepam_valium] Diazepam (Valium)
     - [lorazepam_ativan] Lorazepam (Ativan)
     - [clonazepam_klonopin] Clonazepam (Klonopin)
     - [chlordiazepoxide_librium] Chlordiazepoxide (Librium)
     - [temazepam_restoril] Temazepam (Restoril)
     - [oxazepam_serax] Oxazepam (Serax)
     - [midazolam_versed] Midazolam (Versed)
     - [triazolam_halcion] Triazolam (Halcion)
     - [other_please_specify] Other (please specify)
     - [don_t_know_not_sure] Don’t know / Not sure
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_indication] What was the original reason for taking this medication?
   - Type: **select** | Required: true
   - **Options**:
     - [prescribed_medical_use] Prescribed medical use
     - [self_medication_for_symptoms_without_pre] Self-medication for symptoms (without prescription)
     - [recreational_non_medical_use] Recreational / non-medical use
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_dose_escalation] Have you found yourself needing higher doses over time?
   - Type: **yesno** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_source] How did you obtain this medication?
   - Type: **select** | Required: true
   - **Options**:
     - [mild_slight_increase] Mild (slight increase)
     - [moderate_double_or_more_than_initial_dos] Moderate (double or more than initial dose)
     - [severe_much_higher_than_prescribed_or_sa] Severe (much higher than prescribed or safe range)
   - **Logic (Shown If)**:
     - Trigger QID 81 eq 'yes'
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_concurrent_use] Have you been using any other substances at the same time?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_only_benzodiazepines] No, only benzodiazepines
     - [alcohol] Alcohol
     - [opioids] Opioids
     - [cannabis] Cannabis
     - [stimulants_e_g_cocaine_amphetamines] Stimulants (e.g., cocaine, amphetamines)
     - [other_prescription_medications] Other prescription medications
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_consequences] What impact has this had on your life?
   - Type: **yesno** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_treatment_attempts] Have you tried to stop or reduce use before?
   - Type: **select** | Required: true
   - **Options**:
     - [never_attempted] No, never attempted abstinence
     - [success] Yes, maintained abstinence successfully
     - [relapsed_once] Yes, relapsed once after abstinence
     - [multiple_relapses] Yes, multiple relapses after abstinence
     - [not_applicable] Not applicable / Not currently using
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 84 eq 'yes'
     - Trigger QID 242 contains 'benzodiazepine'

---
## Section: Risk assessment/Screening (Type: general)

---
## Section: Family History (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_family_history_substance_use_in_family] Is there a history of substance use in your family?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_family_history_psychiatric_illness_in_family] Has anyone in your family experienced psychiatric illness?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_family_history_family_conflict_or_instability] Have there been any conflicts or instability in your family?
   - Type: **yesno** | Required: true

---
## Section: History of Presenting Illness (Type: benzodiazepine)

### [sub_benzodiazepine_history_of_presenting_illness_age_at_first_use] How old were you when you first used benzodiazepines?
   - Type: **select** | Required: true
   - Note: _Number(Age Group)/Prefer not to say_
   - **Options**:
     - [under_15] <15 years
     - [15_20] 15–20 years
     - [20_25] 20–25 years
     - [25_30] 25–30 years
     - [30_plus] 30+ years
     - [prefer_not_to_answer] Prefer not to answer
     - [cannot_recall] Cannot recall
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_circumstances_of_initiation] What were the circumstances when you first started?
   - Type: **select** | Required: true
   - **Options**:
     - [prescribed_by_a_doctor_for_anxiety_insom] Prescribed by a doctor (for anxiety, insomnia, seizures, other medical condition)
     - [self_medication_without_prescription] Self-medication without prescription
     - [recreational_curiosity_peer_influence] Recreational / curiosity / peer influence
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_circumstances_of_initiation_who_introduced_or_provided_the_drug_at_initiation] Who first introduced you to this substance?
   - Type: **select** | Required: true
   - **Options**:
     - [doctor_healthcare_provider] Doctor / healthcare provider
     - [family_member] Family member
     - [friend_peer] Friend / peer
     - [bought_without_prescription] Bought without prescription
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 87 neq 'prefer_not_to_answer'
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_initial_subjective_effects] How did you feel when you first used it?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [relaxed_calm] Relaxed / calm
     - [relief_from_anxiety] Relief from anxiety
     - [improved_sleep] Improved sleep
     - [euphoria_high] Euphoria / “high”
     - [muscle_relaxation] Muscle relaxation
     - [more_sociable_less_inhibited] More sociable / less inhibited
     - [sedated_drowsy] Sedated / drowsy
     - [confused_foggy] Confused / foggy
     - [dizzy_unsteady] Dizzy / unsteady
     - [no_effect] No effect
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_frequency_and_quantity] How often and how much do you typically use?
   - Type: **select** | Required: true
   - **Options**:
     - [one_time_experimental_use] One-time / experimental use
     - [occasional_use_less_than_once_per_month] Occasional use (less than once per month)
     - [intermittent_use_a_few_times_per_month] Intermittent use (a few times per month)
     - [weekly_use] Weekly use
     - [several_times_per_week] Several times per week
     - [daily_use] Daily use
     - [multiple_times_per_day] Multiple times per day
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_frequency_and_quantity_quantity_on_day_of_use] On days when you use, how much do you typically take?
   - Type: **select** | Required: true
   - **Options**:
     - [low_dose_within_prescribed_dose] Low dose (Within prescribed dose)
     - [moderate_dose_more_than_prescribed_but_n] Moderate dose (More than prescribed but not excessive)
     - [high_dose_well_above_therapeutic_range] High dose (well above therapeutic range)
     - [very_high_dose_binge_use] Very high dose / binge use
     - [unable_to_specify_varies_widely] Unable to specify / varies widely
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_route_of_administration] How do you usually take this substance?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [oral_as_prescribed] Oral (as prescribed)
     - [oral_misuse_e_g_crushed_chewed] Oral (misuse, e.g., crushed/chewed)
     - [intranasal_snorted] Intranasal (snorted)
     - [intravenous_injected] Intravenous (injected)
     - [intramuscular_injected] Intramuscular (injected)
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_tolerance] Have you noticed needing more to get the same effect?
   - Type: **select** | Required: true
   - **Options**:
     - [yes] Yes
     - [no] No
     - [unsure] Unsure
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_reason_for_continued_use] What keeps you using this substance?
   - Type: **select** | Required: true
   - **Options**:
     - [increase_dose_on_my_own] Increase dose on my own
     - [doctor_increased_prescription] Doctor increased prescription
     - [combine_with_other_substances] Combine with other substances
     - [continue_same_dose_despite_less_effect] Continue same dose despite less effect
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 93 eq 'yes'
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_withdrawal_symptoms] Have you experienced any withdrawal symptoms?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_e_g_anxiety_insomnia_restlessness] Mild (e.g., anxiety, insomnia, restlessness)
     - [moderate_e_g_tremors_sweating_nausea_irr] Moderate (e.g., tremors, sweating, nausea, irritability)
     - [severe_e_g_seizures_severe_agitation_hal] Severe (e.g., seizures, severe agitation, hallucinations)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_craving] Do you experience strong cravings?
   - Type: **select** | Required: true
   - **Options**:
     - [none] None
     - [mild] Mild
     - [moderate] Moderate
     - [strong] Strong
     - [very_strong_overwhelming] Very strong / overwhelming
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_craving_response_towards_strong_cravings] How do you typically respond to these cravings?
   - Type: **select** | Required: true
   - **Options**:
     - [able_to_resist] Able to resist
     - [distract_self_use_coping_strategies] Distract self / use coping strategies
     - [use_benzodiazepines_to_relieve_cravings] Use benzodiazepines to relieve cravings
     - [use_other_substances_instead] Use other substances instead
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 96 neq 'none'
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_loss_of_control] Do you sometimes feel you"ve lost control over your use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_always_able_to_control_use] No, always able to control use
     - [occasionally_sometimes_take_more_than_in] Occasionally (sometimes take more than intended)
     - [frequently_often_unable_to_control_amoun] Frequently (often unable to control amount or frequency)
     - [always_consistently_unable_to_control_us] Always / consistently unable to control use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_abstinence_or_relapse] Have you tried to stop or cut back before?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never_attempted_abstinence] No, never attempted abstinence
     - [yes_maintained_abstinence_successfully] Yes, maintained abstinence successfully
     - [yes_relapsed_once_after_abstinence] Yes, relapsed once after abstinence
     - [yes_multiple_relapses_after_abstinence] Yes, multiple relapses after abstinence
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_medical_complications] Have you experienced any medical complications?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_medical_complications] No medical complications
     - [sedation_excessive_drowsiness] Sedation / excessive drowsiness
     - [cognitive_impairment_memory_attention_di] Cognitive impairment (memory, attention difficulties)
     - [dizziness_balance_problems] Dizziness / balance problems
     - [gastrointestinal_issues_nausea_constipat] Gastrointestinal issues (nausea, constipation)
     - [respiratory_depression_difficulty_breath] Respiratory depression (difficulty breathing)
     - [mental_health_issues_depression_anxiety] Mental health issues (depression, anxiety)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_psychological_complications] Have you noticed any psychological effects?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_psychological_complications] No psychological complications
     - [anxiety_agitation] Anxiety / agitation
     - [depression_low_mood] Depression / low mood
     - [cognitive_issues_memory_attention_concen] Cognitive issues (memory, attention, concentration difficulties)
     - [mood_swings_irritability] Mood swings / irritability
     - [psychotic_symptoms_rare_hallucinations_d] Psychotic symptoms (rare: hallucinations, delusions)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_social_consequences] How has this affected your relationships?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_social_consequences] No social consequences
     - [relationship_family_conflicts] Relationship/family conflicts
     - [loss_of_friends_social_isolation] Loss of friends / social isolation
     - [difficulties_at_work_or_school] Difficulties at work or school
     - [legal_issues_related_to_behavior] Legal issues related to behavior
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_occupational_consequences] Has this impacted your work or studies?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_occupational_academic_consequences] No occupational/academic consequences
     - [reduced_productivity_performance_issues] Reduced productivity / performance issues
     - [absenteeism_frequent_leave] Absenteeism / frequent leave
     - [job_loss_or_suspension] Job loss or suspension
     - [academic_difficulties_poor_grades_missed] Academic difficulties (poor grades, missed classes)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_financial_consequences] Have there been any financial consequences?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_financial_consequences] No financial consequences
     - [spending_more_money_than_intended_on_ben] Spending more money than intended on benzodiazepines
     - [debt_accumulation_borrowing_money] Debt accumulation / borrowing money
     - [loss_of_income_or_employment] Loss of income or employment
     - [difficulty_meeting_household_or_personal] Difficulty meeting household or personal expenses
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_legal_issues] Have you had any legal issues related to substance use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_legal_issues] No legal issues
     - [arrests_or_detentions] Arrests or detentions
     - [fines_or_penalties] Fines or penalties
     - [probation_or_community_service] Probation or community service
     - [other_legal_encounters_please_specify] Other legal encounters (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_past_treatments] Have you sought treatment or help before?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_previous_treatment] No previous treatment
     - [outpatient_counseling_therapy] Outpatient counseling / therapy
     - [inpatient_residential_rehabilitation] Inpatient / residential rehabilitation
     - [detoxification_programs] Detoxification programs
     - [medication_assisted_treatment_e_g_taperi] Medication-assisted treatment (e.g., tapering schedules)
     - [support_groups_e_g_na_peer_support] Support groups (e.g., NA, peer support)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_history_of_presenting_illness_motivation_to_quit] On a scale of 1-10, how motivated are you to make a change?
   - Type: **select** | Required: true
   - **Options**:
     - [not_motivated_at_all] Not motivated at all
     - [slightly_motivated] Slightly motivated
     - [moderately_motivated] Moderately motivated
     - [highly_motivated] Highly motivated
     - [already_taking_steps_to_quit] Already taking steps to quit
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

---
## Section: Risk Behaviors & Coping Skills (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_risk_behaviors_coping_skills_stress_management] How do you typically manage stress in your life?
   - Type: **select** | Required: true
   - **Options**:
     - [never] Never
     - [exercise] Exercise
     - [relaxation_meditation] Relaxation / Meditation
     - [talking_to_someone] Talking to someone
     - [professional_help] Professional help
     - [alcohol_substance_use] Alcohol / Substance use
     - [avoidance_sleep] Avoidance / Sleep
     - [distraction_tv_games_internet_etc] Distraction (TV, games, internet, etc.)
     - [other_please_specify] Other (please specify)

### [gen_risk_assessment_screening_risk_behaviors_coping_skills_coping_style_adaptive_vs_malad] Would you describe your coping style as mostly adaptive or maladaptive?
   - Type: **select** | Required: true
   - **Options**:
     - [never] Never
     - [rarely] Rarely
     - [sometimes] Sometimes
     - [often] Often
     - [always] Always

### [gen_risk_assessment_screening_risk_behaviors_coping_skills_leisure_activities] What activities do you enjoy in your leisure time?
   - Type: **select** | Required: true
   - **Options**:
     - [never] Never
     - [rarely] Rarely
     - [sometimes] Sometimes
     - [often] Often
     - [always] Always

---
## Section: Past History (Type: general)

### [gen_past_history_medical_illnesses] Do you have any medical conditions we should know about?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_past] Yes- Past
     - [yes_ongoing] Yes- Ongoing
     - [no] No

### [gen_past_history_medical_illnesses_if_yes_please_specify] If yes, could you please specify which conditions?
   - Type: **text** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 41 eq 'yes_past_or_yes_ongoing'

### [gen_past_history_psychiatric_illnesses] Have you been diagnosed with any psychiatric conditions?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_past] Yes- Past
     - [yes_ongoing] Yes- Ongoing
     - [no] No

### [gen_past_history_past_substance_use] Have you used any substances in the past?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_past] Yes- Past
     - [yes_ongoing] Yes- Ongoing
     - [no] No

### [substance_screening_which_substances] Which of the following substances have you used?
   - Type: **multi_select** | Required: true
   - Note: _Select all that apply. This helps us tailor the assessment to your specific situation._
   - **Options**:
     - [benzodiazepine] Benzodiazepines (e.g., Xanax, Valium, Ativan)
     - [stimulant] Stimulants (e.g., Cocaine, Amphetamines, Methamphetamine)
     - [cannabis] Cannabis (Marijuana, Hash)
     - [opioid] Opioids (e.g., Heroin, Morphine, Oxycodone)
     - [alcohol] Alcohol
     - [none] None of the above
   - **Logic (Shown If)**:
     - Trigger QID 45 eq 'yes_past'
     - Trigger QID 45 eq 'yes_ongoing'

---
## Section: Withdrawal Type (Type: benzodiazepine)

### [sub_benzodiazepine_withdrawal_type_anxiety_panic] Have you experienced anxiety or panic attacks?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_anxiety] Yes- Anxiety
     - [high] High
     - [yes_panic] Yes - Panic
     - [moderate] Moderate
     - [yes_both] Yes - Both
     - [low] Low
     - [no] No
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_irritability_agitation] Have you felt irritable or agitated?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_insomnia_nightmares] Have you had trouble sleeping or experienced nightmares?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_tremors_muscle_twitching] Have you noticed tremors or muscle twitching?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_sweating_headaches_sensitivity] Have you experienced sweating, headaches, or sensitivity to light/sound?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_nausea_stomach_issues] Have you had nausea or stomach issues?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_confusion_memory_problems] Have you experienced confusion or memory problems?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

### [sub_benzodiazepine_withdrawal_type_seizure_history] Have you ever had a seizure?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'benzodiazepine'

---
## Section: Protective Factors (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_protective_factors_supportive_family] Do you have a supportive family network?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_protective_factors_positive_peer_group] Would you say you have a positive peer group?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_protective_factors_religion_or_spirituality] Does religion or spirituality play a role in your life?
   - Type: **select** | Required: true
   - **Options**:
     - [not_at_all_important] Not at all important
     - [slightly_important] Slightly important
     - [moderately_important] Moderately important
     - [very_important] Very important
     - [extremely_important] Extremely important

### [gen_risk_assessment_screening_protective_factors_healthy_coping_strategies] Do you have any healthy coping strategies you use?
   - Type: **select** | Required: true
   - **Options**:
     - [never] Never
     - [rarely] Rarely
     - [sometimes] Sometimes
     - [often] Often
     - [always] Always

---
## Section: Family History (Type: general)

### [gen_family_history_substance_use_in_family_if_yes_please_specify] If yes, could you tell us more about this?
   - Type: **text** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 16 eq 'yes'

### [gen_family_history_psychiatric_illnesses_in_famil_if_yes_please_specify] If yes, could you share more details?
   - Type: **text** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 17 eq 'yes'

### [gen_family_history_family_environment] How would you describe your family environment growing up?
   - Type: **select** | Required: true
   - **Options**:
     - [supportive] Supportive
     - [mixed_some_support_some_conflict] Mixed (some support, some conflict)
     - [conflictual] Conflictual
     - [abusive] Abusive
     - [prefer_not_to_answer] Prefer not to answer

---
## Section: History (Type: stimulant)

### [sub_stimulant_history_type] What type of stimulant have you been using?
   - Type: **select** | Required: true
   - **Options**:
     - [cocaine] Cocaine
     - [amphetamines_methamphetamine] Amphetamines / Methamphetamine
     - [methylphenidate_ritalin_concerta] Methylphenidate (Ritalin, Concerta)
     - [mdma_ecstasy] MDMA / Ecstasy
     - [caffeine_high_use] Caffeine (high use)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_pattern] How would you describe your pattern of use?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_use] Occasional / social use
     - [regular_daily_use] Regular / daily use
     - [binge_use_periods_of_heavy_use] Binge use (periods of heavy use)
     - [sporadic_unpredictable_use] Sporadic / unpredictable use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_positive_effects] What positive effects have you experienced?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [increased_energy_alertness] Increased energy / alertness
     - [improved_focus_concentration] Improved focus / concentration
     - [elevated_mood_euphoria] Elevated mood / euphoria
     - [increased_sociability_confidence] Increased sociability / confidence
     - [weight_loss_appetite_suppression] Weight loss / appetite suppression
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_adverse_effects] Have you experienced any negative or adverse effects?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [sleep_disturbances_insomnia] Sleep disturbances / insomnia
     - [anxiety_agitation_irritability] Anxiety / agitation / irritability
     - [mood_swings_depression] Mood swings / depression
     - [increased_heart_rate_palpitations] Increased heart rate / palpitations
     - [appetite_loss_weight_loss] Appetite loss / weight loss
     - [social_relationship_problems] Social / relationship problems
     - [legal_occupational_problems] Legal / occupational problems
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_risk_behaviors] Have you engaged in any risky behaviors while using?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [driving_under_the_influence] Driving under the influence
     - [unsafe_sexual_activity] Unsafe sexual activity
     - [sharing_or_using_unclean_equipment_e_g_n] Sharing or using unclean equipment (e.g., needles)
     - [financial_or_occupational_risk_taking] Financial or occupational risk-taking
     - [legal_issues_encounters_with_law_enforce] Legal issues / encounters with law enforcement
     - [aggressive_or_violent_behavior] Aggressive or violent behavior
     - [other_please_specify] Other (please specify)
     - [none] None
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_consequences] What consequences have you experienced from use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [health_problems_physical_or_mental] Health problems (physical or mental)
     - [relationship_issues_family_friends_partn] Relationship issues (family, friends, partners)
     - [occupational_academic_difficulties] Occupational / academic difficulties
     - [legal_problems_arrests] Legal problems / arrests
     - [financial_difficulties] Financial difficulties
     - [social_isolation_loss_of_support] Social isolation / loss of support
     - [other_please_specify] Other (please specify)
     - [none] None
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

---
## Section: Personal & Psychiatric History (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_personal_psychiatric_history_trauma_or_abuse] Have you experienced any trauma or abuse in your life?
   - Type: **select** | Required: true
   - **Options**:
     - [yes] Yes
     - [no] No
     - [prefer_not_to_say] Prefer not to say

### [gen_risk_assessment_screening_personal_psychiatric_history_depression_anxiety] Have you ever experienced depression or anxiety?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_depression] Yes, depression
     - [yes_anxiety] Yes, anxiety
     - [yes_both] Yes, both
     - [no] No
     - [prefer_not_to_answer] Prefer not to answer

### [gen_risk_assessment_screening_personal_psychiatric_history_adhd_or_other_disorders] Have you been diagnosed with ADHD or other mental health conditions?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_adhd] Yes, ADHD
     - [yes_other_psychiatric_disorder_s] Yes, other psychiatric disorder(s)
     - [no_history_of_adhd_or_other_psychiatric_] No history of ADHD or other psychiatric disorders
     - [prefer_not_to_answer] Prefer not to answer

### [gen_risk_assessment_screening_personal_psychiatric_history_previous_psychiatric_treatment] Have you received psychiatric treatment in the past?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_outpatient_counseling_therapy] Yes – outpatient counseling/therapy
     - [yes_inpatient_psychiatric_hospitalizatio] Yes – inpatient psychiatric hospitalization
     - [yes_medication_treatment] Yes – medication treatment
     - [yes_other_please_specify] Yes – other (please specify)
     - [no] No
     - [prefer_not_to_answer] Prefer not to answer

---
## Section: Personal History (Type: general)

### [gen_personal_history_birth_and_developmental_histor] Could you share about your birth and early development?
   - Type: **select** | Required: true
   - **Options**:
     - [normal_birth_and_development] Normal birth and development
     - [minor_delays_speech_motor_learning] Minor delays (speech, motor, learning)
     - [significant_delays_or_difficulties_in_de] Significant delays or difficulties in development
     - [not_sure_don_t_know] Not sure / don’t know
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_childhood_adjustment] How would you describe your childhood adjustment?
   - Type: **select** | Required: true
   - **Options**:
     - [well_adjusted_generally_positive_childho] Well-adjusted (generally positive childhood)
     - [minor_difficulties_occasional_challenges] Minor difficulties (occasional challenges, but managed)
     - [moderate_difficulties_frequent_struggles] Moderate difficulties (frequent struggles at home/school/with peers)
     - [severe_difficulties_persistent_problems_] Severe difficulties (persistent problems or distress)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_education_history] Could you tell us about your educational journey?
   - Type: **select** | Required: true
   - **Options**:
     - [currently_studying_doing_well_without_di] Currently studying, doing well without difficulties
     - [currently_studying_with_some_minor_diffi] Currently studying, with some minor difficulties
     - [completed_education_without_difficulties] Completed education without difficulties
     - [minor_difficulties_occasional_struggles_] Minor difficulties (occasional struggles, but completed education)
     - [moderate_difficulties_frequent_struggles] Moderate difficulties (frequent struggles, some interruptions)
     - [severe_difficulties_significant_academic] Severe difficulties (significant academic problems or school dropouts)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_occupational_history] What has your work history been like?
   - Type: **select** | Required: true
   - **Options**:
     - [employed_stable] Employed, stable
     - [employed_some_difficulties] Employed, some difficulties
     - [unemployed_student_homemaker] Unemployed / student / homemaker
     - [past_employment_with_difficulties] Past employment with difficulties
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_marital_and_sexual_history] Could you share about your relationship and sexual history?
   - Type: **select** | Required: true
   - **Options**:
     - [single_no_sexual_activity] Single, no sexual activity
     - [single_sexually_active] Single, sexually active
     - [married_cohabiting_stable_relationship] Married / cohabiting, stable relationship
     - [married_cohabiting_some_difficulties] Married / cohabiting, some difficulties
     - [divorced_separated_widowed] Divorced / separated / widowed
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_social_relationships] How would you describe your social relationships?
   - Type: **select** | Required: true
   - **Options**:
     - [supportive_and_positive] Supportive and positive
     - [mostly_positive_occasional_conflicts] Mostly positive, occasional conflicts
     - [mixed_both_supportive_and_conflictual] Mixed – both supportive and conflictual
     - [poor_frequent_conflicts_or_isolation] Poor – frequent conflicts or isolation
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_forensic_or_legal_history] Have you had any legal issues in the past?
   - Type: **select** | Required: true
   - **Options**:
     - [no_legal_issues] No legal issues
     - [minor_legal_issues_e_g_warnings_fines] Minor legal issues (e.g., warnings, fines)
     - [moderate_legal_issues_e_g_arrests_short_] Moderate legal issues (e.g., arrests, short-term detentions)
     - [serious_legal_issues_e_g_convictions_lon] Serious legal issues (e.g., convictions, long-term imprisonment)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_personal_history_leisure_and_coping] What do you do for leisure and how do you cope with stress?
   - Type: **select** | Required: true
   - **Options**:
     - [regular_leisure_activities_healthy_copin] Regular leisure activities, healthy coping
     - [some_leisure_activities_occasional_healt] Some leisure activities, occasional healthy coping
     - [minimal_leisure_activities_mostly_unheal] Minimal leisure activities, mostly unhealthy coping
     - [no_leisure_activities_primarily_unhealth] No leisure activities, primarily unhealthy coping
     - [prefer_not_to_answer] Prefer not to answer

---
## Section: History of Presenting Illness (Type: stimulant)

### [sub_stimulant_history_of_presenting_illness_age_at_first_use] How old were you when you first used stimulants?
   - Type: **select** | Required: true
   - Note: _Number(Age Group)/Prefer not to say_
   - **Options**:
     - [under_15] <15 years
     - [15_20] 15–20 years
     - [20_25] 20–25 years
     - [25_30] 25–30 years
     - [30_plus] 30+ years
     - [prefer_not_to_answer] Prefer not to answer
     - [cannot_recall] Cannot recall
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_circumstances_of_initiation] What were the circumstances when you first started using?
   - Type: **select** | Required: true
   - **Options**:
     - [peer_pressure_friends_offered] Peer pressure / friends offered
     - [curiosity_experimentation] Curiosity / experimentation
     - [to_enhance_academic_or_work_performance] To enhance academic or work performance
     - [to_cope_with_stress_or_emotional_issues] To cope with stress or emotional issues
     - [recreational_social_use] Recreational / social use
     - [accidental_or_prescribed_use_medical] Accidental or prescribed use (medical)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_initial_subjective_effects] How did you feel when you first used stimulants?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [increased_energy_alertness] Increased energy / alertness
     - [euphoria_feeling_high] Euphoria / feeling high
     - [enhanced_focus_concentration] Enhanced focus / concentration
     - [increased_sociability_talkativeness] Increased sociability / talkativeness
     - [anxiety_nervousness] Anxiety / nervousness
     - [irritability_agitation] Irritability / agitation
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_frequency_and_quantity] How often and how much do you typically use?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_use_small_amounts] Occasional / social use, small amounts
     - [regular_weekly_moderate_amounts] Regular (weekly), moderate amounts
     - [daily_use_moderate_amounts] Daily use, moderate amounts
     - [daily_use_high_amounts] Daily use, high amounts
     - [binge_use_large_amounts_in_short_periods] Binge use (large amounts in short periods)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_route_of_administration] How do you usually take stimulants?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [oral_swallowed_pills_powder] Oral (swallowed pills, powder)
     - [smoked_inhaled] Smoked / inhaled
     - [snorted_insufflated] Snorted / insufflated
     - [injected_intravenous_or_subcutaneous] Injected (intravenous or subcutaneous)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_tolerance] Have you noticed needing more to get the same effect?
   - Type: **select** | Required: true
   - **Options**:
     - [no_dose_remains_the_same] No, dose remains the same
     - [mild_tolerance_occasionally_need_slightl] Mild tolerance (occasionally need slightly higher doses)
     - [moderate_tolerance_regularly_need_higher] Moderate tolerance (regularly need higher doses)
     - [high_tolerance_significant_increase_in_d] High tolerance (significant increase in dose needed)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_withdrawal_symptoms] Have you experienced withdrawal symptoms when stopping?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_e_g_fatigue_irritability_mild_depre] Mild (e.g., fatigue, irritability, mild depression)
     - [moderate_e_g_strong_cravings_anxiety_sle] Moderate (e.g., strong cravings, anxiety, sleep disturbances)
     - [severe_e_g_intense_depression_agitation_] Severe (e.g., intense depression, agitation, significant functional impairment)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_craving] Do you experience strong cravings for stimulants?
   - Type: **select** | Required: true
   - **Options**:
     - [no_cravings] No cravings
     - [mild_occasional_cravings] Mild / occasional cravings
     - [moderate_frequent_cravings] Moderate / frequent cravings
     - [severe_intense_cravings_interfering_with] Severe / intense cravings interfering with daily life
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_loss_of_control] Do you sometimes feel you"ve lost control over your use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_always_able_to_control_use] No, always able to control use
     - [occasionally_sometimes_take_more_than_in] Occasionally (sometimes take more than intended)
     - [frequently_often_unable_to_control_amoun] Frequently (often unable to control amount or frequency)
     - [always_consistently_unable_to_control_us] Always / consistently unable to control use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_abstinence_or_relapse] Have you tried to stop or cut back on stimulant use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never_attempted_abstinence] No, never attempted abstinence
     - [yes_maintained_abstinence_successfully] Yes, maintained abstinence successfully
     - [yes_relapsed_once_after_abstinence] Yes, relapsed once after abstinence
     - [yes_multiple_relapses_after_abstinence] Yes, multiple relapses after abstinence
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_medical_complications] Have you experienced any medical complications from stimulant use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_medical_complications] No medical complications
     - [cardiovascular_problems_high_blood_press] Cardiovascular problems (high blood pressure, palpitations)
     - [neurological_problems_headaches_seizures] Neurological problems (headaches, seizures, tremors)
     - [sleep_disturbances] Sleep disturbances
     - [gastrointestinal_issues_nausea_appetite_] Gastrointestinal issues (nausea, appetite changes)
     - [weight_loss_or_malnutrition] Weight loss or malnutrition
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_psychological_complications] Have you noticed any psychological effects from use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_psychological_complications] No psychological complications
     - [anxiety_agitation] Anxiety / agitation
     - [depression_low_mood] Depression / low mood
     - [irritability_mood_swings] Irritability / mood swings
     - [paranoia_suspiciousness] Paranoia / suspiciousness
     - [hallucinations_psychotic_symptoms] Hallucinations / psychotic symptoms
     - [cognitive_issues_memory_attention_concen] Cognitive issues (memory, attention, concentration difficulties)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_social_consequences] How has stimulant use affected your relationships?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_social_consequences] No social consequences
     - [relationship_family_conflicts] Relationship/family conflicts
     - [loss_of_friends_social_isolation] Loss of friends / social isolation
     - [difficulties_at_work_or_school] Difficulties at work or school
     - [legal_issues_related_to_behavior] Legal issues related to behavior
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_occupational_consequences] Has stimulant use impacted your work or studies?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_occupational_academic_consequences] No occupational/academic consequences
     - [reduced_productivity_performance_issues] Reduced productivity / performance issues
     - [absenteeism_frequent_leave] Absenteeism / frequent leave
     - [job_loss_or_suspension] Job loss or suspension
     - [academic_difficulties_poor_grades_missed] Academic difficulties (poor grades, missed classes)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_financial_consequences] Have there been any financial consequences from use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_financial_consequences] No financial consequences
     - [spending_more_money_than_intended_on_sti] Spending more money than intended on stimulants
     - [debt_accumulation_borrowing_money] Debt accumulation / borrowing money
     - [loss_of_income_or_employment] Loss of income or employment
     - [difficulty_meeting_household_or_personal] Difficulty meeting household or personal expenses
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_legal_issues] Have you had any legal issues related to stimulant use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_legal_issues] No legal issues
     - [arrests_or_detentions] Arrests or detentions
     - [fines_or_penalties] Fines or penalties
     - [probation_or_community_service] Probation or community service
     - [other_legal_encounters_please_specify] Other legal encounters (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_past_treatments] Have you sought treatment or help for stimulant use before?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_previous_treatment] No previous treatment
     - [outpatient_counseling_therapy] Outpatient counseling / therapy
     - [inpatient_residential_rehabilitation] Inpatient / residential rehabilitation
     - [detoxification_programs] Detoxification programs
     - [medication_assisted_treatment] Medication-assisted treatment
     - [support_groups_e_g_na_peer_support] Support groups (e.g., NA, peer support)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_history_of_presenting_illness_motivation_to_quit] How motivated are you to make a change? (1-10)
   - Type: **select** | Required: true
   - **Options**:
     - [not_motivated_at_all] Not motivated at all
     - [slightly_motivated] Slightly motivated
     - [moderately_motivated] Moderately motivated
     - [highly_motivated] Highly motivated
     - [already_taking_steps_to_quit] Already taking steps to quit
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

---
## Section: Withdrawal Type (Type: stimulant)

### [sub_stimulant_withdrawal_type_fatigue_low_energy] Have you experienced fatigue or low energy?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_hypersomnia] Have you been sleeping more than usual?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_increased_appetite] Have you noticed an increased appetite?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_depressed_mood] Have you felt depressed or down?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_anxiety_irritability] Have you felt anxious or irritable?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_intense_cravings] Have you experienced intense cravings?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_vivid_dreams] Have you had vivid or disturbing dreams?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

### [sub_stimulant_withdrawal_type_trouble_concentrating] Have you had trouble concentrating?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'stimulant'

---
## Section: Sleep & Daily Functioning (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_sleep_daily_functioning_insomnia] Do you experience difficulty sleeping or insomnia?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_sleep_daily_functioning_irregular_sleep] Is your sleep schedule irregular?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_sleep_daily_functioning_daytime_fatigue] Do you feel fatigued during the day?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_sleep_daily_functioning_effect_on_daily_functioning] How does this affect your daily functioning?
   - Type: **yesno** | Required: true

---
## Section: Premorbid personality (Type: general)

### [gen_premorbid_personality_traits] How would you describe your personality traits?
   - Type: **select** | Required: true
   - **Options**:
     - [generally_easy_going_and_adaptable] Generally easy-going and adaptable
     - [generally_responsible_and_conscientious] Generally responsible and conscientious
     - [generally_introverted_reserved] Generally introverted / reserved
     - [generally_impulsive_or_risk_taking] Generally impulsive or risk-taking
     - [mixed_traits_combination_of_above] Mixed traits (combination of above)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_premorbid_personality_interpersonal_relations] How would you characterize your relationships with others?
   - Type: **select** | Required: true
   - **Options**:
     - [generally_positive_and_cooperative] Generally positive and cooperative
     - [mostly_positive_occasional_conflicts] Mostly positive, occasional conflicts
     - [mixed_supportive_with_some_difficulties] Mixed – supportive with some difficulties
     - [difficult_or_conflict_prone_relationship] Difficult or conflict-prone relationships
     - [prefer_not_to_answer] Prefer not to answer

### [gen_premorbid_personality_hobbies] Do you have any hobbies or interests?
   - Type: **select** | Required: true
   - **Options**:
     - [regular_hobbies_interests_actively_engag] Regular hobbies/interests, actively engaged
     - [some_hobbies_interests_occasional_engage] Some hobbies/interests, occasional engagement
     - [few_hobbies_interests_minimal_engagement] Few hobbies/interests, minimal engagement
     - [no_hobbies_or_interests] No hobbies or interests
     - [prefer_not_to_answer] Prefer not to answer

### [gen_premorbid_personality_hobbies_if_yes_please_specify_hobbies_name] If yes, what hobbies do you enjoy?
   - Type: **text** | Required: true
   - **Logic (Shown If)**:
     - Trigger QID 62 neq 'no_hobbies_or_interests'

---
## Section: Social & Environmental Factors (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_social_environmental_factors_peer_pressure] Have you felt peer pressure to use substances?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_social_environmental_factors_community_cultural_norms] Do community or cultural norms influence your substance use?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_social_environmental_factors_exposure_to_substance_use] Have you been exposed to substance use in your environment?
   - Type: **yesno** | Required: true

---
## Section: History (Type: cannabis)

### [sub_cannabis_history_age_of_initiation] How old were you when you first tried cannabis?
   - Type: **select** | Required: true
   - **Options**:
     - [15_years] <15 years
     - [15_20_years] 15–20 years
     - [20_25_years] 20–25 years
     - [prefer_not_to_answer] Prefer not to answer
     - [cannot_recall] Cannot recall
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_form] What form of cannabis do you typically use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [oral_ingestion_edibles_beverages_tinctur] Oral ingestion (edibles, beverages, tinctures)
     - [smoking_joints_pipes_bongs_hookah] Smoking (joints, pipes, bongs, hookah)
     - [vaporization_vapes_e_cigarettes] Vaporization (vapes, e-cigarettes)
     - [transdermal_topical_lotions_patches_rare] Transdermal / topical (lotions, patches — rare)
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_pattern] How would you describe your pattern of cannabis use?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_use] Occasional / social use
     - [regular_daily_use] Regular / daily use
     - [binge_use_periods_of_heavy_use] Binge use (periods of heavy use)
     - [unpredictable_use] Unpredictable use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_effects] What effects do you experience from cannabis?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [relaxation_calmness] Relaxation / calmness
     - [euphoria_feeling_high] Euphoria / feeling high
     - [increased_sociability_talkativeness] Increased sociability / talkativeness
     - [improved_sleep] Improved sleep
     - [increased_creativity_focus] Increased creativity / focus
     - [anxiety_paranoia] Anxiety / paranoia
     - [dry_mouth_red_eyes] Dry mouth / red eyes
     - [memory_or_concentration_difficulties] Memory or concentration difficulties
     - [increased_heart_rate_palpitations] Increased heart rate / palpitations
     - [social_relationship_problems] Social / relationship problems
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_cognitive_issues] Have you noticed any cognitive issues from cannabis use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_cognitive_issues] No cognitive issues
     - [mild_occasional_forgetfulness_slight_con] Mild (occasional forgetfulness, slight concentration difficulties)
     - [moderate_frequent_memory_lapses_attentio] Moderate (frequent memory lapses, attention problems)
     - [severe_significant_difficulties_affectin] Severe (significant difficulties affecting daily functioning)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_psychotic_symptoms] Have you experienced any psychotic symptoms?
   - Type: **select** | Required: true
   - **Options**:
     - [no_psychotic_symptoms] No psychotic symptoms
     - [mild_brief_e_g_paranoia_mild_hallucinati] Mild / brief (e.g., paranoia, mild hallucinations)
     - [moderate_e_g_visual_or_auditory_hallucin] Moderate (e.g., visual or auditory hallucinations, delusions)
     - [severe_e_g_persistent_hallucinations_del] Severe (e.g., persistent hallucinations, delusions, requiring medical attention)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

---
## Section: Mental status Examination (Type: general)

### [gen_mental_status_examination_appearance_and_behavior] How would you describe your general appearance and behavior?
   - Type: **select** | Required: true
   - **Options**:
     - [well_groomed_appropriate_behavior] Well-groomed, appropriate behavior
     - [adequately_groomed_generally_appropriate] Adequately groomed, generally appropriate behavior
     - [neglected_grooming_withdrawn_or_passive_] Neglected grooming, withdrawn or passive behavior
     - [disorganized_appearance_restless_or_agit] Disorganized appearance, restless or agitated behavior
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_speech] How would you describe your speech patterns?
   - Type: **select** | Required: true
   - **Options**:
     - [normal_rate_tone_and_flow] Normal rate, tone, and flow
     - [slightly_slow_or_reduced] Slightly slow or reduced
     - [rapid_or_pressured] Rapid or pressured
     - [irregular_e_g_interruptions_tangential] Irregular (e.g., interruptions, tangential)
     - [minimal_or_very_little_speech] Minimal or very little speech
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_mood_and_affect] How has your mood been lately?
   - Type: **select** | Required: true
   - **Options**:
     - [stable_and_appropriate] Stable and appropriate
     - [mildly_low_anxious] Mildly low / anxious
     - [depressed_sad] Depressed / sad
     - [irritable_easily_frustrated] Irritable / easily frustrated
     - [elevated_unusually_cheerful] Elevated / unusually cheerful
     - [labile_frequent_mood_changes] Labile (frequent mood changes)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_thought] Have you noticed any changes in your thinking?
   - Type: **select** | Required: true
   - **Options**:
     - [logical_coherent_and_goal_directed] Logical, coherent, and goal-directed
     - [slowed_or_blocked] Slowed or blocked
     - [rapid_or_racing_thoughts] Rapid or racing thoughts
     - [tangential_or_disorganized] Tangential or disorganized
     - [circumstantial_overly_detailed] Circumstantial / overly detailed
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_perception] How is your perception of things around you?
   - Type: **select** | Required: true
   - **Options**:
     - [normal_perception_no_unusual_experiences] Normal perception, no unusual experiences
     - [occasionally_distracted_or_preoccupied] Occasionally distracted or preoccupied
     - [illusions_misinterpreting_real_objects_s] Illusions (misinterpreting real objects/sounds)
     - [hallucinations_hearing_seeing_or_sensing] Hallucinations (hearing, seeing, or sensing things not there)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_cognition] How would you rate your cognitive functioning?
   - Type: **select** | Required: true
   - **Options**:
     - [alert_attentive_and_oriented] Alert, attentive, and oriented
     - [mild_difficulties_with_attention_or_memo] Mild difficulties with attention or memory
     - [moderate_difficulties_frequent_forgetful] Moderate difficulties (frequent forgetfulness, distractibility)
     - [severe_difficulties_disoriented_unable_t] Severe difficulties (disoriented, unable to focus or recall)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_insight] Do you have insight into your current situation?
   - Type: **select** | Required: true
   - **Options**:
     - [good_insight_aware_and_acknowledges_diff] Good insight (aware and acknowledges difficulties)
     - [partial_insight_some_awareness_but_minim] Partial insight (some awareness, but minimizes difficulties)
     - [poor_insight_limited_awareness_denies_pr] Poor insight (limited awareness, denies problems)
     - [no_insight_no_awareness_of_difficulties] No insight (no awareness of difficulties)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_mental_status_examination_judgment] How would you describe your judgment and decision-making?
   - Type: **select** | Required: true
   - **Options**:
     - [intact_makes_sound_appropriate_decisions] Intact (makes sound, appropriate decisions)
     - [mildly_impaired_occasional_poor_decision] Mildly impaired (occasional poor decisions)
     - [moderately_impaired_frequent_poor_decisi] Moderately impaired (frequent poor decisions)
     - [severely_impaired_consistently_poor_or_u] Severely impaired (consistently poor or unsafe decisions)
     - [prefer_not_to_answer] Prefer not to answer

---
## Section: Withdrawal Questions (Type: general)

### [gen_withdrawal_questions_recently_reduced_or_stopped] Have you recently reduced or stopped using any substances?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_abruptly_stopped] Yes – Abruptly stopped
     - [yes_gradually_reduced] Yes – Gradually reduced
     - [yes_with_medical_supervision] Yes – With medical supervision
     - [yes_without_medical_supervision] Yes – Without medical supervision
     - [no_still_using_at_same_level] No – Still using at same level
     - [no_increased_use_instead] No – Increased use instead

### [gen_withdrawal_questions_onset_of_symptoms] When did you first notice any symptoms?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_symptoms_started_within_a_day] Yes, symptoms started within a day
     - [yes_symptoms_started_after_1_3_days] Yes, symptoms started after 1–3 days
     - [yes_symptoms_started_after_a_week] Yes, symptoms started after a week
     - [no_symptoms_noticed] No symptoms noticed
     - [not_sure] Not sure

### [gen_withdrawal_questions_severity_1_to_10] On a scale of 1 to 10, how would you rate the severity?
   - Type: **select** | Required: true
   - **Options**:
     - [1_2_very_mild_hardly_noticeable] 1–2: Very mild, hardly noticeable
     - [3_4_mild_manageable_without_much_discomf] 3–4: Mild, manageable without much discomfort
     - [5_6_moderate_noticeable_and_uncomfortabl] 5–6: Moderate, noticeable and uncomfortable
     - [7_8_severe_difficult_to_manage] 7–8: Severe, difficult to manage
     - [9_10_very_severe_disabling_required_medi] 9–10: Very severe, disabling, required medical attention
     - [prefer_not_to_answer] Prefer not to answer

### [gen_withdrawal_questions_time_of_day_pattern] Do symptoms occur at a particular time of day?
   - Type: **select** | Required: true
   - **Options**:
     - [only_once_a_day] Only once a day
     - [multiple_times_a_day] Multiple times a day
     - [continuous_throughout_the_day] Continuous throughout the day
     - [sporadic_unpredictable] Sporadic / unpredictable
     - [prefer_not_to_answer] Prefer not to answer

### [gen_withdrawal_questions_interference_with_daily_life] How much do these symptoms interfere with your daily life?
   - Type: **select** | Required: true
   - **Options**:
     - [none_no_interference] None / no interference
     - [mild_interference_some_discomfort_but_da] Mild interference (some discomfort, but daily life manageable)
     - [moderate_interference_frequent_disruptio] Moderate interference (frequent disruptions, some activities affected)
     - [severe_interference_daily_life_significa] Severe interference (daily life significantly affected)
     - [very_severe_disabling_unable_to_perform_] Very severe / disabling (unable to perform normal activities)
     - [prefer_not_to_answer] Prefer not to answer

### [gen_withdrawal_questions_cravings_to_relieve_symptoms] Do you experience cravings to relieve these symptoms?
   - Type: **select** | Required: true
   - **Options**:
     - [no_cravings] No cravings
     - [mild_cravings_occasional_manageable] Mild cravings (occasional, manageable)
     - [moderate_cravings_frequent_sometimes_dif] Moderate cravings (frequent, sometimes difficult to resist)
     - [strong_cravings_intense_hard_to_resist] Strong cravings (intense, hard to resist)
     - [very_strong_uncontrollable_cravings] Very strong / uncontrollable cravings
     - [prefer_not_to_answer] Prefer not to answer

### [gen_withdrawal_questions_ever_needed_medical_help] Have you ever needed medical help for withdrawal?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never] No, never
     - [yes_minor_assistance_advice_outpatient_s] Yes, minor assistance (advice, outpatient support)
     - [yes_significant_medical_help_emergency_v] Yes, significant medical help (emergency visit, hospitalization)
     - [prefer_not_to_answer] Prefer not to answer

---
## Section: Cognitive & Behavioral Patterns (Type: general)
   (Child of Section ID: 2)

### [gen_risk_assessment_screening_cognitive_behavioral_patterns_impulsivity] Would you describe yourself as impulsive at times?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_cognitive_behavioral_patterns_novelty_seeking] Do you tend to seek out new experiences?
   - Type: **select** | Required: true
   - **Options**:
     - [never] Never
     - [rarely] Rarely
     - [sometimes] Sometimes
     - [often] Often
     - [always] Always

### [gen_risk_assessment_screening_cognitive_behavioral_patterns_poor_decision_making] Do you sometimes struggle with decision-making?
   - Type: **yesno** | Required: true

### [gen_risk_assessment_screening_cognitive_behavioral_patterns_aggression_or_risk_taking] Have you engaged in aggressive behavior or risk-taking?
   - Type: **select** | Required: true
   - **Options**:
     - [yes_aggression] Yes-Aggression
     - [yes_risk_taking] Yes-Risk-Taking
     - [yes_both] Yes-Both
     - [no] No

---
## Section: History of Presenting Illness (Type: cannabis)

### [sub_cannabis_history_of_presenting_illness_circumstances_of_initiation] What were the circumstances when you first started using cannabis?
   - Type: **select** | Required: true
   - **Options**:
     - [peer_pressure_friends_offered] Peer pressure / friends offered
     - [curiosity_experimentation] Curiosity / experimentation
     - [to_cope_with_stress_or_emotional_issues] To cope with stress or emotional issues
     - [recreational_social_use] Recreational / social use
     - [medical_or_prescribed_use] Medical or prescribed use
     - [accidental_exposure] Accidental exposure
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_initial_subjective_effects] How did you feel when you first used cannabis?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [euphoria_feeling_high] Euphoria / feeling high
     - [relaxation_calmness] Relaxation / calmness
     - [increased_sociability_talkativeness] Increased sociability / talkativeness
     - [altered_perception_of_time_or_space] Altered perception of time or space
     - [anxiety_nervousness] Anxiety / nervousness
     - [paranoia_suspiciousness] Paranoia / suspiciousness
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_frequency_and_quantity] How often and how much cannabis do you typically use?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_use_small_amounts] Occasional / social use, small amounts
     - [regular_weekly_moderate_amounts] Regular (weekly), moderate amounts
     - [daily_use_moderate_amounts] Daily use, moderate amounts
     - [daily_use_high_amounts] Daily use, high amounts
     - [binge_use_large_amounts_in_short_periods] Binge use (large amounts in short periods)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_route_of_administration] How do you usually consume cannabis?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [smoked_joints_pipes_bongs] Smoked (joints, pipes, bongs)
     - [vaporized_e_cigarette] Vaporized / e-cigarette
     - [oral_edibles_capsules] Oral (edibles, capsules)
     - [topical_via_skin] Topical / via skin
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_tolerance] Have you noticed needing more cannabis to get the same effect?
   - Type: **select** | Required: true
   - **Options**:
     - [no_dose_remains_the_same] No, dose remains the same
     - [mild_tolerance_occasionally_need_slightl] Mild tolerance (occasionally need slightly higher amounts)
     - [moderate_tolerance_regularly_need_higher] Moderate tolerance (regularly need higher amounts)
     - [high_tolerance_significant_increase_in_a] High tolerance (significant increase in amount needed)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_withdrawal_symptoms] Have you experienced withdrawal symptoms when stopping cannabis?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_e_g_irritability_anxiety_sleep_dist] Mild (e.g., irritability, anxiety, sleep disturbances)
     - [moderate_e_g_strong_cravings_mood_swings] Moderate (e.g., strong cravings, mood swings, appetite changes)
     - [severe_e_g_significant_functional_impair] Severe (e.g., significant functional impairment, intense cravings)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_craving] Do you experience strong cravings for cannabis?
   - Type: **select** | Required: true
   - **Options**:
     - [no_cravings] No cravings
     - [mild_occasional_cravings] Mild / occasional cravings
     - [moderate_frequent_cravings] Moderate / frequent cravings
     - [severe_intense_cravings_interfering_with] Severe / intense cravings interfering with daily life
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_loss_of_control] Do you sometimes feel you"ve lost control over your cannabis use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_always_able_to_control_use] No, always able to control use
     - [occasionally_sometimes_take_more_than_in] Occasionally (sometimes take more than intended)
     - [frequently_often_unable_to_control_amoun] Frequently (often unable to control amount or frequency)
     - [always_consistently_unable_to_control_us] Always / consistently unable to control use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_abstinence_or_relapse] Have you tried to stop or cut back on cannabis use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never_attempted_abstinence] No, never attempted abstinence
     - [yes_maintained_abstinence_successfully] Yes, maintained abstinence successfully
     - [yes_relapsed_once_after_abstinence] Yes, relapsed once after abstinence
     - [yes_multiple_relapses_after_abstinence] Yes, multiple relapses after abstinence
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_medical_complications] Have you experienced any medical complications from cannabis use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_medical_complications] No medical complications
     - [respiratory_problems_chronic_cough_bronc] Respiratory problems (chronic cough, bronchitis)
     - [cardiovascular_issues_palpitations_high_] Cardiovascular issues (palpitations, high blood pressure)
     - [sleep_disturbances] Sleep disturbances
     - [gastrointestinal_issues_nausea_appetite_] Gastrointestinal issues (nausea, appetite changes)
     - [neurological_problems_headaches_dizzines] Neurological problems (headaches, dizziness)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_psychological_complications] Have you noticed any psychological effects from cannabis use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_psychological_complications] No psychological complications
     - [anxiety_agitation] Anxiety / agitation
     - [depression_low_mood] Depression / low mood
     - [paranoia_suspiciousness] Paranoia / suspiciousness
     - [mood_swings_irritability] Mood swings / irritability
     - [psychotic_symptoms_hallucinations_delusi] Psychotic symptoms (hallucinations, delusions)
     - [cognitive_issues_memory_attention_concen] Cognitive issues (memory, attention, concentration difficulties)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_social_consequences] How has cannabis use affected your relationships?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_social_consequences] No social consequences
     - [relationship_family_conflicts] Relationship/family conflicts
     - [loss_of_friends_social_isolation] Loss of friends / social isolation
     - [difficulties_at_work_or_school] Difficulties at work or school
     - [legal_issues_related_to_behavior] Legal issues related to behavior
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_occupational_consequences] Has cannabis use impacted your work or studies?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_occupational_academic_consequences] No occupational/academic consequences
     - [reduced_productivity_performance_issues] Reduced productivity / performance issues
     - [absenteeism_frequent_leave] Absenteeism / frequent leave
     - [job_loss_or_suspension] Job loss or suspension
     - [academic_difficulties_poor_grades_missed] Academic difficulties (poor grades, missed classes)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_financial_consequences] Have there been any financial consequences from cannabis use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_financial_consequences] No financial consequences
     - [spending_more_money_than_intended_on_can] Spending more money than intended on cannabis
     - [debt_accumulation_borrowing_money] Debt accumulation / borrowing money
     - [loss_of_income_or_employment] Loss of income or employment
     - [difficulty_meeting_household_or_personal] Difficulty meeting household or personal expenses
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_legal_issues] Have you had any legal issues related to cannabis use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_legal_issues] No legal issues
     - [arrests_or_detentions] Arrests or detentions
     - [fines_or_penalties] Fines or penalties
     - [probation_or_community_service] Probation or community service
     - [other_legal_encounters_please_specify] Other legal encounters (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_past_treatments] Have you sought treatment or help for cannabis use before?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_previous_treatment] No previous treatment
     - [outpatient_counseling_therapy] Outpatient counseling / therapy
     - [inpatient_residential_rehabilitation] Inpatient / residential rehabilitation
     - [detoxification_programs] Detoxification programs
     - [medication_assisted_treatment] Medication-assisted treatment
     - [support_groups_e_g_na_peer_support] Support groups (e.g., NA, peer support)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_history_of_presenting_illness_motivation_to_quit] How motivated are you to make a change regarding cannabis? (1-10)
   - Type: **select** | Required: true
   - **Options**:
     - [not_motivated_at_all] Not motivated at all
     - [slightly_motivated] Slightly motivated
     - [moderately_motivated] Moderately motivated
     - [highly_motivated] Highly motivated
     - [already_taking_steps_to_quit] Already taking steps to quit
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

---
## Section: Withdrawal Type (Type: cannabis)

### [sub_cannabis_withdrawal_type_irritability_anger] Have you felt irritable or angry?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_withdrawal_type_anxiety_depression] Have you experienced anxiety or depression?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_withdrawal_type_restlessness] Have you felt restless?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_withdrawal_type_sleep_problems] Have you had sleep problems?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_withdrawal_type_appetite_or_weight_loss] Have you experienced appetite or weight loss?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_withdrawal_type_sweating_chills_shakiness] Have you experienced sweating, chills, or shakiness?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

### [sub_cannabis_withdrawal_type_cannabis_cravings] Have you had strong cravings for cannabis?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'cannabis'

---
## Section: History (Type: opioid)

### [sub_opioid_history_type] What type of opioid have you been using?
   - Type: **select** | Required: true
   - **Options**:
     - [natural_opioids_opium_morphine_codeine] Natural opioids (opium, morphine, codeine)
     - [semi_synthetic_opioids_heroin_oxycodone_] Semi-synthetic opioids (heroin, oxycodone, hydrocodone)
     - [synthetic_opioids_tramadol_fentanyl_meth] Synthetic opioids (tramadol, fentanyl, methadone, buprenorphine)
     - [prescription_painkillers_medical_use_non] Prescription painkillers (medical use, non-medical use)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_progression] How has your opioid use progressed over time?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_experimental_use_only] Occasional / experimental use only
     - [gradual_increase_in_frequency_or_dose] Gradual increase in frequency or dose
     - [rapid_escalation_to_regular_use] Rapid escalation to regular use
     - [shift_from_prescription_use_to_non_medic] Shift from prescription use to non-medical use
     - [progression_from_oral_use_to_injection_h] Progression from oral use to injection / higher-risk use
     - [stable_use_without_major_change] Stable use without major change
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_withdrawal] Have you experienced withdrawal symptoms from opioids?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_symptoms_e_g_restlessness_sweating_] Mild symptoms (e.g., restlessness, sweating, mild discomfort)
     - [moderate_symptoms_e_g_muscle_aches_insom] Moderate symptoms (e.g., muscle aches, insomnia, anxiety, cravings)
     - [severe_symptoms_e_g_vomiting_diarrhea_se] Severe symptoms (e.g., vomiting, diarrhea, severe pain, inability to function)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_overdose_history] Have you ever experienced an overdose?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never] No, never
     - [yes_once_no_medical_help_required] Yes, once (no medical help required)
     - [yes_once_required_medical_help_hospitali] Yes, once (required medical help / hospitalization)
     - [yes_multiple_times_no_medical_help_requi] Yes, multiple times (no medical help required)
     - [yes_multiple_times_required_medical_help] Yes, multiple times (required medical help / hospitalization)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_needle_sharing] Have you ever shared needles or injection equipment?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never] No, never
     - [yes_once_or_rarely] Yes, once or rarely
     - [yes_occasionally] Yes, occasionally
     - [yes_frequently] Yes, frequently
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_consequences] What consequences have you experienced from opioid use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [none] None
     - [health_problems_e_g_infections_liver_iss] Health problems (e.g., infections, liver issues, overdose)
     - [financial_difficulties] Financial difficulties
     - [legal_troubles_or_arrests] Legal troubles or arrests
     - [relationship_family_conflicts] Relationship/family conflicts
     - [work_school_problems] Work/school problems
     - [social_isolation] Social isolation
     - [other_please_specify] Other (please specify)
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

---
## Section: History of Presenting Illness (Type: opioid)

### [sub_opioid_history_of_presenting_illness_age_at_first_use] How old were you when you first used opioids?
   - Type: **select** | Required: true
   - Note: _Number(Age Group)/Prefer not to say_
   - **Options**:
     - [under_15] <15 years
     - [15_20] 15–20 years
     - [20_25] 20–25 years
     - [25_30] 25–30 years
     - [30_plus] 30+ years
     - [prefer_not_to_answer] Prefer not to answer
     - [cannot_recall] Cannot recall
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_circumstances_of_initiation] What were the circumstances when you first started using opioids?
   - Type: **select** | Required: true
   - **Options**:
     - [prescribed_for_medical_reasons] Prescribed for medical reasons
     - [recreational_social_use] Recreational / social use
     - [peer_pressure_friends_offered] Peer pressure / friends offered
     - [to_cope_with_stress_emotional_issues_or_] To cope with stress, emotional issues, or pain
     - [accidental_or_experimental_use] Accidental or experimental use
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_initial_subjective_effects] How did you feel when you first used opioids?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [euphoria_feeling_high] Euphoria / feeling high
     - [pain_relief_relaxation] Pain relief / relaxation
     - [sedation_drowsiness] Sedation / drowsiness
     - [increased_sociability_talkativeness] Increased sociability / talkativeness
     - [nausea_vomiting] Nausea / vomiting
     - [dizziness_lightheadedness] Dizziness / lightheadedness
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_frequency_and_quantity] How often and how much do you typically use opioids?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_use_small_amounts] Occasional / social use, small amounts
     - [regular_weekly_moderate_amounts] Regular (weekly), moderate amounts
     - [daily_use_moderate_amounts] Daily use, moderate amounts
     - [daily_use_high_amounts] Daily use, high amounts
     - [binge_use_large_amounts_in_short_periods] Binge use (large amounts in short periods)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_route_of_administration] How do you usually take opioids?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [oral_pills_capsules_syrup] Oral (pills, capsules, syrup)
     - [smoked_inhaled] Smoked / inhaled
     - [snorted_insufflated] Snorted / insufflated
     - [injected_intravenous_or_subcutaneous] Injected (intravenous or subcutaneous)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_tolerance] Have you noticed needing more opioids to get the same effect?
   - Type: **select** | Required: true
   - **Options**:
     - [no_dose_remains_the_same] No, dose remains the same
     - [mild_tolerance_occasionally_need_slightl] Mild tolerance (occasionally need slightly higher amounts)
     - [moderate_tolerance_regularly_need_higher] Moderate tolerance (regularly need higher amounts)
     - [high_tolerance_significant_increase_in_a] High tolerance (significant increase in amount needed)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_withdrawal_symptoms] Have you experienced withdrawal symptoms when stopping opioids?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_e_g_muscle_aches_mild_anxiety_restl] Mild (e.g., muscle aches, mild anxiety, restlessness)
     - [moderate_e_g_strong_cravings_sweating_na] Moderate (e.g., strong cravings, sweating, nausea, insomnia)
     - [severe_e_g_significant_functional_impair] Severe (e.g., significant functional impairment, intense physical symptoms)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_craving] Do you experience strong cravings for opioids?
   - Type: **select** | Required: true
   - **Options**:
     - [no_cravings] No cravings
     - [mild_occasional_cravings] Mild / occasional cravings
     - [moderate_frequent_cravings] Moderate / frequent cravings
     - [severe_intense_cravings_interfering_with] Severe / intense cravings interfering with daily life
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_loss_of_control] Do you sometimes feel you"ve lost control over your opioid use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_always_able_to_control_use] No, always able to control use
     - [occasionally_sometimes_take_more_than_in] Occasionally (sometimes take more than intended)
     - [frequently_often_unable_to_control_amoun] Frequently (often unable to control amount or frequency)
     - [always_consistently_unable_to_control_us] Always / consistently unable to control use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_abstinence_or_relapse] Have you tried to stop or cut back on opioid use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never_attempted_abstinence] No, never attempted abstinence
     - [yes_maintained_abstinence_successfully] Yes, maintained abstinence successfully
     - [yes_relapsed_once_after_abstinence] Yes, relapsed once after abstinence
     - [yes_multiple_relapses_after_abstinence] Yes, multiple relapses after abstinence
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_medical_complications] Have you experienced any medical complications from opioid use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_medical_complications] No medical complications
     - [infectious_diseases_hiv_hepatitis_b_c] Infectious diseases (HIV, Hepatitis B/C)
     - [respiratory_problems_breathing_difficult] Respiratory problems (breathing difficulties, infections)
     - [cardiovascular_issues_heart_problems_blo] Cardiovascular issues (heart problems, blood pressure changes)
     - [gastrointestinal_issues_constipation_nau] Gastrointestinal issues (constipation, nausea)
     - [neurological_problems_dizziness_seizures] Neurological problems (dizziness, seizures)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_psychological_complications] Have you noticed any psychological effects from opioid use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_psychological_complications] No psychological complications
     - [anxiety_agitation] Anxiety / agitation
     - [depression_low_mood] Depression / low mood
     - [irritability_mood_swings] Irritability / mood swings
     - [paranoia_suspiciousness] Paranoia / suspiciousness
     - [cognitive_issues_memory_attention_concen] Cognitive issues (memory, attention, concentration difficulties)
     - [psychotic_symptoms_hallucinations_delusi] Psychotic symptoms (hallucinations, delusions)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_social_consequences] How has opioid use affected your relationships?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_social_consequences] No social consequences
     - [relationship_family_conflicts] Relationship/family conflicts
     - [loss_of_friends_social_isolation] Loss of friends / social isolation
     - [difficulties_at_work_or_school] Difficulties at work or school
     - [legal_issues_related_to_behavior] Legal issues related to behavior
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_occupational_consequences] Has opioid use impacted your work or studies?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_occupational_academic_consequences] No occupational/academic consequences
     - [reduced_productivity_performance_issues] Reduced productivity / performance issues
     - [absenteeism_frequent_leave] Absenteeism / frequent leave
     - [job_loss_or_suspension] Job loss or suspension
     - [academic_difficulties_poor_grades_missed] Academic difficulties (poor grades, missed classes)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_financial_consequences] Have there been any financial consequences from opioid use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_financial_consequences] No financial consequences
     - [spending_more_money_than_intended_on_opi] Spending more money than intended on opioids
     - [debt_accumulation_borrowing_money] Debt accumulation / borrowing money
     - [loss_of_income_or_employment] Loss of income or employment
     - [difficulty_meeting_household_or_personal] Difficulty meeting household or personal expenses
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_legal_issues] Have you had any legal issues related to opioid use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_legal_issues] No legal issues
     - [arrests_or_detentions] Arrests or detentions
     - [fines_or_penalties] Fines or penalties
     - [probation_or_community_service] Probation or community service
     - [other_legal_encounters_please_specify] Other legal encounters (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_past_treatments] Have you sought treatment or help for opioid use before?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_previous_treatment] No previous treatment
     - [outpatient_counseling_therapy] Outpatient counseling / therapy
     - [inpatient_residential_rehabilitation] Inpatient / residential rehabilitation
     - [detoxification_programs] Detoxification programs
     - [medication_assisted_treatment_e_g_methad] Medication-assisted treatment (e.g., methadone, buprenorphine)
     - [support_groups_e_g_na_peer_support] Support groups (e.g., NA, peer support)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_history_of_presenting_illness_motivation_to_quit] How motivated are you to make a change regarding opioids? (1-10)
   - Type: **select** | Required: true
   - **Options**:
     - [not_motivated_at_all] Not motivated at all
     - [slightly_motivated] Slightly motivated
     - [moderately_motivated] Moderately motivated
     - [highly_motivated] Highly motivated
     - [already_taking_steps_to_quit] Already taking steps to quit
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

---
## Section: Withdrawal Type (Type: opioid)

### [sub_opioid_withdrawal_type_muscle_or_bone_pain] Have you experienced muscle or bone pain?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_runny_nose_tearing_yawning] Have you had a runny nose, tearing, or yawning?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_nausea_vomiting_diarrhea] Have you experienced nausea, vomiting, or diarrhea?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_goosebumps_sweating_chills] Have you had goosebumps, sweating, or chills?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_restlessness_anxiety_irritabil] Have you felt restless, anxious, or irritable?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_sleep_problems_fatigue] Have you had sleep problems or fatigue?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_pupil_dilation_light_sensitivi] Have you experienced pupil dilation or light sensitivity?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

### [sub_opioid_withdrawal_type_opioid_cravings] Have you had strong cravings for opioids?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'opioid'

---
## Section: History (Type: alcohol)

### [sub_alcohol_history_age_of_initiation] How old were you when you first started drinking alcohol?
   - Type: **select** | Required: true
   - **Options**:
     - [15_years] <15 years
     - [15_20_years] 15–20 years
     - [20_25_years] 20–25 years
     - [prefer_not_to_answer] Prefer not to answer
     - [cannot_recall] Cannot recall
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_pattern_of_use] How would you describe your pattern of alcohol use?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_drinking] Occasional / social drinking
     - [weekend_or_recreational_use] Weekend or recreational use
     - [regular_several_times_a_week] Regular (several times a week)
     - [daily_use] Daily use
     - [binge_drinking_large_amounts_in_short_pe] Binge drinking (large amounts in short period)
     - [escalating_increasing_over_time] Escalating / increasing over time
     - [periods_of_abstinence_followed_by_relaps] Periods of abstinence followed by relapse
     - [cannot_specify_unsure] Cannot specify / unsure
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_morning_drinking] Do you drink alcohol in the morning?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never] No, never
     - [occasionally_rarely_in_the_morning] Occasionally (rarely in the morning)
     - [sometimes_a_few_times_per_month] Sometimes (a few times per month)
     - [often_weekly_or_more] Often (weekly or more)
     - [daily_every_morning] Daily / every morning
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_withdrawal] Have you experienced withdrawal symptoms from alcohol?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_symptoms_e_g_anxiety_irritability_m] Mild symptoms (e.g., anxiety, irritability, mild tremors)
     - [moderate_symptoms_e_g_sweating_nausea_in] Moderate symptoms (e.g., sweating, nausea, insomnia, cravings)
     - [severe_symptoms_e_g_seizures_hallucinati] Severe symptoms (e.g., seizures, hallucinations, vomiting, inability to function)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_blackouts] Have you ever experienced blackouts from drinking?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never] No, never
     - [yes_rarely_once_or_twice] Yes, rarely (once or twice)
     - [yes_occasionally_a_few_times] Yes, occasionally (a few times)
     - [yes_frequently_many_times] Yes, frequently (many times)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_medical_complications] Have you experienced any medical complications from alcohol use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_medical_complications] No medical complications
     - [liver_problems_hepatitis_cirrhosis] Liver problems (hepatitis, cirrhosis)
     - [cardiovascular_issues_high_blood_pressur] Cardiovascular issues (high blood pressure, heart problems)
     - [gastrointestinal_problems_ulcers_gastrit] Gastrointestinal problems (ulcers, gastritis)
     - [neurological_problems_memory_issues_neur] Neurological problems (memory issues, neuropathy)
     - [sleep_disturbances] Sleep disturbances
     - [mental_health_issues_depression_anxiety] Mental health issues (depression, anxiety)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_social_occupational_legal_issu] How has alcohol affected your social, work, or legal situation?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_issues] No issues
     - [relationship_family_conflicts] Relationship/family conflicts
     - [loss_of_friends_social_isolation] Loss of friends / social isolation
     - [work_or_school_difficulties] Work or school difficulties
     - [legal_troubles_arrests_fines_duis] Legal troubles (arrests, fines, DUIs)
     - [financial_problems] Financial problems
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

---
## Section: History of Presenting Illness (Type: alcohol)

### [sub_alcohol_history_of_presenting_illness_circumstances_of_initiation] What were the circumstances when you first started drinking?
   - Type: **select** | Required: true
   - **Options**:
     - [social_peer_pressure_friends_offered] Social / peer pressure / friends offered
     - [curiosity_experimentation] Curiosity / experimentation
     - [to_cope_with_stress_emotional_issues_or_] To cope with stress, emotional issues, or personal problems
     - [family_environment_parental_influence] Family environment / parental influence
     - [cultural_religious_events] Cultural / religious events
     - [accidental_exposure] Accidental exposure
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_initial_subjective_effects] How did you feel when you first drank alcohol?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [euphoria_feeling_relaxed] Euphoria / feeling relaxed
     - [increased_sociability_talkativeness] Increased sociability / talkativeness
     - [disinhibition_risk_taking_behavior] Disinhibition / risk-taking behavior
     - [drowsiness_sedation] Drowsiness / sedation
     - [nausea_vomiting] Nausea / vomiting
     - [dizziness_lightheadedness] Dizziness / lightheadedness
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_frequency_and_quantity] How often and how much alcohol do you typically drink?
   - Type: **select** | Required: true
   - **Options**:
     - [occasional_social_drinking_small_amounts] Occasional / social drinking, small amounts
     - [regular_weekly_moderate_amounts] Regular (weekly), moderate amounts
     - [daily_use_moderate_amounts] Daily use, moderate amounts
     - [daily_use_high_amounts] Daily use, high amounts
     - [binge_drinking_large_amounts_in_short_pe] Binge drinking (large amounts in short periods)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_route_of_administration] What type of alcohol do you usually drink?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [oral_drinking_beverages] Oral (drinking beverages)
     - [other_please_specify_e_g_alcohol_in_food] Other (please specify, e.g., alcohol in food or medicinal forms)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_tolerance] Have you noticed needing more alcohol to get the same effect?
   - Type: **select** | Required: true
   - **Options**:
     - [no_dose_remains_the_same] No, dose remains the same
     - [mild_tolerance_occasionally_need_slightl] Mild tolerance (occasionally need slightly higher amounts)
     - [moderate_tolerance_regularly_need_higher] Moderate tolerance (regularly need higher amounts)
     - [high_tolerance_significant_increase_in_a] High tolerance (significant increase in amount needed)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_withdrawal_symptoms] Have you experienced withdrawal symptoms when stopping alcohol?
   - Type: **select** | Required: true
   - **Options**:
     - [no_withdrawal_symptoms] No withdrawal symptoms
     - [mild_e_g_anxiety_mild_tremors_irritabili] Mild (e.g., anxiety, mild tremors, irritability)
     - [moderate_e_g_sweating_nausea_insomnia_st] Moderate (e.g., sweating, nausea, insomnia, strong cravings)
     - [severe_e_g_seizures_hallucinations_signi] Severe (e.g., seizures, hallucinations, significant functional impairment)
     - [required_medical_help_for_withdrawal] Required medical help for withdrawal
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_craving] Do you experience strong cravings for alcohol?
   - Type: **select** | Required: true
   - **Options**:
     - [no_cravings] No cravings
     - [mild_occasional_cravings] Mild / occasional cravings
     - [moderate_frequent_cravings] Moderate / frequent cravings
     - [severe_intense_cravings_interfering_with] Severe / intense cravings interfering with daily life
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_loss_of_control] Do you sometimes feel you"ve lost control over your drinking?
   - Type: **select** | Required: true
   - **Options**:
     - [no_always_able_to_control_use] No, always able to control use
     - [occasionally_sometimes_drink_more_than_i] Occasionally (sometimes drink more than intended)
     - [frequently_often_unable_to_control_amoun] Frequently (often unable to control amount or frequency)
     - [always_consistently_unable_to_control_us] Always / consistently unable to control use
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_abstinence_or_relapse] Have you tried to stop or cut back on alcohol use?
   - Type: **select** | Required: true
   - **Options**:
     - [no_never_attempted_abstinence] No, never attempted abstinence
     - [yes_maintained_abstinence_successfully] Yes, maintained abstinence successfully
     - [yes_relapsed_once_after_abstinence] Yes, relapsed once after abstinence
     - [yes_multiple_relapses_after_abstinence] Yes, multiple relapses after abstinence
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_medical_complications] Have you experienced any medical complications from alcohol use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_medical_complications] No medical complications
     - [liver_problems_hepatitis_cirrhosis] Liver problems (hepatitis, cirrhosis)
     - [gastrointestinal_issues_ulcers_gastritis] Gastrointestinal issues (ulcers, gastritis)
     - [cardiovascular_issues_hypertension_arrhy] Cardiovascular issues (hypertension, arrhythmias)
     - [neurological_problems_tremors_memory_iss] Neurological problems (tremors, memory issues)
     - [sleep_disturbances] Sleep disturbances
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_psychological_complications] Have you noticed any psychological effects from alcohol use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_psychological_complications] No psychological complications
     - [anxiety_agitation] Anxiety / agitation
     - [depression_low_mood] Depression / low mood
     - [irritability_mood_swings] Irritability / mood swings
     - [paranoia_suspiciousness] Paranoia / suspiciousness
     - [cognitive_issues_memory_attention_concen] Cognitive issues (memory, attention, concentration difficulties)
     - [psychotic_symptoms_hallucinations_delusi] Psychotic symptoms (hallucinations, delusions)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_social_consequences] How has alcohol use affected your relationships?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_social_consequences] No social consequences
     - [relationship_family_conflicts] Relationship/family conflicts
     - [loss_of_friends_social_isolation] Loss of friends / social isolation
     - [difficulties_at_work_or_school] Difficulties at work or school
     - [legal_issues_related_to_behavior] Legal issues related to behavior
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_occupational_consequences] Has alcohol use impacted your work or studies?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_occupational_academic_consequences] No occupational/academic consequences
     - [reduced_productivity_performance_issues] Reduced productivity / performance issues
     - [absenteeism_frequent_leave] Absenteeism / frequent leave
     - [job_loss_or_suspension] Job loss or suspension
     - [academic_difficulties_poor_grades_missed] Academic difficulties (poor grades, missed classes)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_financial_consequences] Have there been any financial consequences from alcohol use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_financial_consequences] No financial consequences
     - [spending_more_money_than_intended_on_alc] Spending more money than intended on alcohol
     - [debt_accumulation_borrowing_money] Debt accumulation / borrowing money
     - [loss_of_income_or_employment] Loss of income or employment
     - [difficulty_meeting_household_or_personal] Difficulty meeting household or personal expenses
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_legal_issues] Have you had any legal issues related to alcohol use?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_legal_issues] No legal issues
     - [arrests_or_detentions] Arrests or detentions
     - [fines_or_penalties] Fines or penalties
     - [probation_or_community_service] Probation or community service
     - [other_legal_encounters_please_specify] Other legal encounters (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_past_treatments] Have you sought treatment or help for alcohol use before?
   - Type: **multi_select** | Required: true
   - **Options**:
     - [no_previous_treatment] No previous treatment
     - [outpatient_counseling_therapy] Outpatient counseling / therapy
     - [inpatient_residential_rehabilitation] Inpatient / residential rehabilitation
     - [detoxification_programs] Detoxification programs
     - [medication_assisted_treatment_e_g_naltre] Medication-assisted treatment (e.g., naltrexone, acamprosate, disulfiram)
     - [support_groups_e_g_aa_peer_support] Support groups (e.g., AA, peer support)
     - [other_please_specify] Other (please specify)
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_history_of_presenting_illness_motivation_to_quit] How motivated are you to make a change regarding alcohol? (1-10)
   - Type: **select** | Required: true
   - **Options**:
     - [not_motivated_at_all] Not motivated at all
     - [slightly_motivated] Slightly motivated
     - [moderately_motivated] Moderately motivated
     - [highly_motivated] Highly motivated
     - [already_taking_steps_to_quit] Already taking steps to quit
     - [prefer_not_to_answer] Prefer not to answer
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

---
## Section: Withdrawal Type (Type: alcohol)

### [sub_alcohol_withdrawal_type_tremors] Have you experienced tremors or shaking?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_withdrawal_type_sweating_chills_fever] Have you had sweating, chills, or fever?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_withdrawal_type_nausea_vomiting_diarrhea] Have you experienced nausea, vomiting, or diarrhea?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_withdrawal_type_anxiety_agitation_insomnia_dre] Have you felt anxious, agitated, or had trouble sleeping?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_withdrawal_type_seizures_hallucinations_confus] Have you experienced seizures, hallucinations, or confusion?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

### [sub_alcohol_withdrawal_type_palpitations_bp_rise] Have you had heart palpitations or elevated blood pressure?
   - Type: **yesno** | Required: true
   - **Options**:
     - [high] High
     - [moderate] Moderate
     - [low] Low
     - [none] None
   - **Logic (Shown If)**:
     - Trigger QID 242 contains 'alcohol'

---
