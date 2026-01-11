package com.stravawidget.api

import retrofit2.http.Field
import retrofit2.http.FormUrlEncoded
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Query

interface StravaApi {

    @FormUrlEncoded
    @POST("oauth/token")
    suspend fun exchangeToken(
        @Field("client_id") clientId: String,
        @Field("client_secret") clientSecret: String,
        @Field("code") code: String,
        @Field("grant_type") grantType: String = "authorization_code"
    ): TokenResponse

    @FormUrlEncoded
    @POST("oauth/token")
    suspend fun refreshToken(
        @Field("client_id") clientId: String,
        @Field("client_secret") clientSecret: String,
        @Field("refresh_token") refreshToken: String,
        @Field("grant_type") grantType: String = "refresh_token"
    ): TokenResponse

    @GET("api/v3/athlete/activities")
    suspend fun getActivities(
        @Header("Authorization") authorization: String,
        @Query("after") after: Long,
        @Query("per_page") perPage: Int = 200
    ): List<Activity>
}

data class TokenResponse(
    val access_token: String,
    val refresh_token: String,
    val expires_at: Long,
    val expires_in: Long,
    val token_type: String
)

data class Activity(
    val id: Long,
    val name: String,
    val type: String,
    val sport_type: String?,
    val start_date: String,
    val start_date_local: String,
    val distance: Double,
    val moving_time: Int,
    val elapsed_time: Int,
    val total_elevation_gain: Double?
)
