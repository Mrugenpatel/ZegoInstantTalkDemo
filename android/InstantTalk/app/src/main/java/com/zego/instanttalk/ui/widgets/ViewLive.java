package com.zego.instanttalk.ui.widgets;

import android.content.Context;
import android.content.res.Resources;
import android.content.res.TypedArray;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.TextureView;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.zego.instanttalk.R;
import com.zego.instanttalk.utils.ZegoAVKitUtil;
import com.zego.zegoavkit2.ZegoAVKit;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */
public class ViewLive extends RelativeLayout {

    /**
     * ZegoAVkit支持3条流同时play, 索引为ZegoRemoteViewIndex.First,
     * ZegoRemoteViewIndex.Second, ZegoRemoteViewIndex.Third
     * 索引值相应为0, 1, 2
     * 自定义publish的流的所引值为100
     */
    public static final int PUBLISH_STREAM_ORDINAL = 100;

    /**
     * 无用的所引值.
     */
    public static final int USELESS_STREAM_ORDINAL = -1;

    /**
     * 标识空流.
     */
    public static final String EMPTY_STREAM_ID = "EMPTY";

    /**
     * 分隔符.
     */
    public static final String SEPARATOR = "&";

    /**
     * 标记空闲的LiveView, tag由流的索引值与流ID拼接而成.
     */
    public static final String TAG_VIEW_IS_FREE = USELESS_STREAM_ORDINAL + SEPARATOR + EMPTY_STREAM_ID;


    private View mRootView;

    private TextView mTvQualityColor;

    private TextView mTvQuality;

    private TextureView mTextureView;

    private Resources mResources;

    private int mLiveQuality = 0;

    private int[] mArrColor;

    private String[] mArrLiveQuality;

    private String mLiveTag;

    public static int getStreamOrdinalFromLiveTag(String liveTag) {
        int streamOrdinal = USELESS_STREAM_ORDINAL;

        if (liveTag != null) {
            String[] arr = liveTag.split(SEPARATOR);
            if (arr != null) {
                streamOrdinal = Integer.valueOf(arr[0]);
            }
        }

        return streamOrdinal;
    }

    public static String getStreamIDFromLiveTag(String liveTag) {
        String streamID = EMPTY_STREAM_ID;

        if (liveTag != null) {
            String[] arr = liveTag.split(SEPARATOR);
            if (arr != null) {
                streamID = arr[1];
            }
        }

        return streamID;
    }

    public ViewLive(Context context) {
        super(context);
    }

    public ViewLive(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public ViewLive(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);

        TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.ViewLive, defStyleAttr, 0);
        boolean isFullScreen = a.getBoolean(R.styleable.ViewLive_isFullScreen, false);
        a.recycle();

        initViews(context, isFullScreen);
    }

    private void initViews(Context context, boolean isFullScreen){

        mResources = context.getResources();

        mArrColor = new int[4];
        mArrColor[0]  = R.drawable.circle_green;
        mArrColor[1]  = R.drawable.circle_yellow;
        mArrColor[2]  = R.drawable.circle_red;
        mArrColor[3]  = R.drawable.circle_gray;

        mArrLiveQuality = mResources.getStringArray(R.array.live_quality);

        if(isFullScreen){
            mRootView = LayoutInflater.from(context).inflate(R.layout.view_live_full_screen, this);
        }else {
            mRootView = LayoutInflater.from(context).inflate(R.layout.view_live, this);
        }

        mTextureView = (TextureView) mRootView.findViewById(R.id.textureView);
        mTvQualityColor = (TextView) mRootView.findViewById(R.id.tv_quality_color);
        mTvQuality = (TextView) mRootView.findViewById(R.id.tv_live_quality);

        // view默认为空闲
        mLiveTag = TAG_VIEW_IS_FREE;
    }


    public boolean isFree(){
        return  TAG_VIEW_IS_FREE.equals(mLiveTag);
    }

    public int getLiveQuality() {
        return mLiveQuality;
    }

    public TextureView getTextureView() {
        return mTextureView;
    }

    public String getLiveTag() {
        return mLiveTag;
    }

    public int getStreamOrdinal(){
        return getStreamOrdinalFromLiveTag(mLiveTag);
    }

    public String getStreamID(){
        return getStreamIDFromLiveTag(mLiveTag);
    }

    public void toFullScreen(ViewLive vlBigView, ZegoAVKit zegoAVKit){

        String liveTagOfBigView = vlBigView.getLiveTag();
        String liveTagOfSmallView = mLiveTag;

        int streamOrdinalOfBigView = getStreamOrdinalFromLiveTag(liveTagOfBigView);
        switch (streamOrdinalOfBigView) {
            case 0:
            case 1:
            case 2:
                zegoAVKit.setRemoteView(ZegoAVKitUtil.getZegoRemoteViewIndexByOrdinal(streamOrdinalOfBigView), mTextureView);
                break;
            case PUBLISH_STREAM_ORDINAL:
                zegoAVKit.setLocalView(mTextureView);
                break;
        }

        int streamOrdinalOfSmallView = getStreamOrdinalFromLiveTag(liveTagOfSmallView);
        switch (streamOrdinalOfSmallView) {
            case 0:
            case 1:
            case 2:
                zegoAVKit.setRemoteView(ZegoAVKitUtil.getZegoRemoteViewIndexByOrdinal(streamOrdinalOfSmallView), vlBigView.getTextureView());
                break;
            case PUBLISH_STREAM_ORDINAL:
                zegoAVKit.setLocalView(vlBigView.getTextureView());
                break;
        }


        int liveQualityOfBigView = vlBigView.getLiveQuality();
        int liveQualityOfSmallView = mLiveQuality;

        vlBigView.setLiveTag(liveTagOfSmallView);
        mLiveTag = liveTagOfBigView;

        vlBigView.setLiveQuality(liveQualityOfSmallView);
        mLiveQuality = liveQualityOfBigView;
    }

    public void setLiveQuality(int quality){
        if(quality >= 0 && quality <= 3){
            mLiveQuality = quality;
            mTvQualityColor.setBackgroundResource(mArrColor[quality]);
            mTvQuality.setText(mResources.getString(R.string.live_quality, mArrLiveQuality[quality]));
        }
    }

    public void setLiveTag(int streamOrdinal, String streamID) {
        mLiveTag = streamOrdinal + SEPARATOR + streamID;
    }

    public void setLiveTag(String liveTag) {
        mLiveTag = liveTag;
    }

    public void setFree(){
        mLiveTag = TAG_VIEW_IS_FREE;
        mLiveQuality = 0;
        setVisibility(View.INVISIBLE);
    }
}
